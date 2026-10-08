;;;; manifest.lisp — The project manifest, compass.sexp, read with the restricted reader
;;;;
;;;; Read-if: adding or changing a manifest key
;;;; See: COMPASS-DRAFT-toolchain-D4, COMPASS-DRAFT-toolchain-D15
;;;; Invariant: a malformed manifest yields findings and defaults, never a crash
;;;; Concerns: security-boundary
;;;; Tests: tests/test-sexp.lisp

(in-package #:compass.model)

(defparameter +manifest-file-name+ "compass.sexp")

(defstruct (federation-entry) namespace path)
(defstruct (manifest-command) name kind text doc)
(defstruct (steward-entry) namespace name approval)

(defun command-name (c) (manifest-command-name c))
(defun command-kind (c) (manifest-command-kind c))
(defun command-text (c) (manifest-command-text c))
(defun command-doc (c) (manifest-command-doc c))
(defun steward-namespace (s) (steward-entry-namespace s))
(defun steward-name (s) (steward-entry-name s))
(defun steward-approval (s) (steward-entry-approval s))

(defclass manifest ()
  ((path :initarg :path :initform nil :reader manifest-path)
   (namespaces :initarg :namespaces :initform '() :reader manifest-namespaces)
   (doc-directory :initarg :doc-directory :initform "doc/" :reader manifest-doc-directory)
   (federation :initarg :federation :initform '() :reader manifest-federation)
   (commands :initarg :commands :initform '() :reader manifest-commands)
   (map :initarg :map :initform '() :reader manifest-map)
   (catalog :initarg :catalog :initform '() :reader manifest-catalog)
   (stewards :initarg :stewards :initform '() :reader manifest-stewards)
   (authorities :initarg :authorities :initform '() :reader manifest-authorities)))

(defun default-manifest ()
  (make-instance 'manifest))

(defparameter *manifest-keys*
  '(:namespaces :doc-directory :federation :commands :map :catalog :stewards
    :authorities))

(defun read-manifest (pathname &key (path +manifest-file-name+))
  "Read the manifest at PATHNAME. Return a MANIFEST (defaults where the file is
missing or malformed) and a list of findings under the rule manifest/valid."
  (let ((findings '())
        (lines nil))
    (labels ((finding (severity line message &rest args)
               (push (make-finding :rule "manifest/valid" :severity severity :path path
                                   :line (or line 1)
                                   :message (apply #'format nil message args))
                     findings))
             (finding-at (line column message &rest args)
               (push (make-finding :rule "manifest/valid" :severity :error :path path
                                   :line (or line 1) :column column
                                   :message (apply #'format nil message args))
                     findings))
             (line-of (form) (and (consp form) lines (gethash form lines)))
             (keyword-name (k)
               (cond ((keywordp k) (string-downcase (symbol-name k)))
                     ((foreign-keyword-p k) (string-downcase (foreign-keyword-name k)))
                     (t nil)))
             (string-list-p (x) (and (listp x) (every #'stringp x)))
             (plist-p (x) (and (listp x) (evenp (length x))
                               (loop for (k) on x by #'cddr
                                     always (or (keywordp k) (foreign-keyword-p k)))))
             (plist-get (plist key) (getf plist key)))
      (let ((text (handler-case (read-text-file pathname)
                    (text-file-error (e)
                      (finding :error 1 "~a" (text-file-error-reason e))
                      (return-from read-manifest
                        (values (default-manifest) (nreverse findings)))))))
        (multiple-value-bind (forms form-lines)
            (handler-case (read-restricted-sexps text)
              (sexp-syntax-error (e)
                (finding-at (sexp-syntax-error-line e) (sexp-syntax-error-column e)
                            "~a" (sexp-syntax-error-message e))
                (return-from read-manifest
                  (values (default-manifest) (nreverse findings)))))
          (setf lines form-lines)
          (unless (and (= (length forms) 1) (plist-p (first forms)))
            (finding :error 1 "the manifest must be a single property list, ~
                              such as (:namespaces (\"NS\") :doc-directory \"doc/\")")
            (return-from read-manifest (values (default-manifest) (nreverse findings))))
          (let* ((plist (first forms))
                 (line (line-of plist))
                 (initargs (list :path pathname)))
            (loop for (key) on plist by #'cddr
                  unless (member key *manifest-keys*)
                    do (finding :warning line "unrecognised manifest key :~a"
                                (keyword-name key)))
            ;; :namespaces
            (let ((ns (plist-get plist :namespaces)))
              (cond ((null ns))
                    ((and (string-list-p ns)
                          (every (lambda (n) (ppcre:scan "^[A-Z][A-Z0-9]*$" n)) ns))
                     (setf (getf initargs :namespaces) ns))
                    (t (finding :error line ":namespaces must be a list of uppercase ~
                                            namespace names, such as (\"COMPASS\")"))))
            ;; :doc-directory
            (let ((dir (plist-get plist :doc-directory)))
              (cond ((null dir))
                    ((and (stringp dir) (plusp (length dir))
                          (not (starts-with-p "/" dir))
                          (not (search ".." dir)))
                     (setf (getf initargs :doc-directory)
                           (if (ends-with-p "/" dir) dir (concatenate 'string dir "/"))))
                    (t (finding :error line ":doc-directory must be a relative path ~
                                            inside the repository, such as \"doc/\""))))
            ;; :federation
            (let ((fed (plist-get plist :federation)))
              (when fed
                (if (and (listp fed) (every #'plist-p fed))
                    (setf (getf initargs :federation)
                          (loop for entry in fed
                                for ns = (getf entry :namespace)
                                for p = (getf entry :path)
                                if (and (stringp ns) (stringp p))
                                  collect (make-federation-entry :namespace ns :path p)
                                else do (finding :error (line-of entry)
                                                 "each :federation entry needs ~
                                                  :namespace and :path strings")))
                    (finding :error line ":federation must be a list of ~
                                          (:namespace \"NS\" :path \"../repo\") entries"))))
            ;; :commands
            (let ((commands (plist-get plist :commands)))
              (when commands
                (if (and (listp commands) (every #'plist-p commands))
                    (setf (getf initargs :commands)
                          (loop for entry in commands
                                for name = (keyword-name (getf entry :name))
                                for shell = (getf entry :shell)
                                for repl = (getf entry :repl)
                                for doc = (getf entry :doc)
                                if (and name (or (stringp shell) (stringp repl))
                                        (not (and shell repl))
                                        (or (null doc) (stringp doc)))
                                  collect (make-manifest-command
                                           :name name :kind (if shell :shell :repl)
                                           :text (or shell repl) :doc doc)
                                else do (finding :error (line-of entry)
                                                 "each :commands entry needs a keyword :name ~
                                                  and exactly one of :shell or :repl (a string)")))
                    (finding :error line ":commands must be a list of command entries"))))
            ;; :map and :catalog are checked lightly in v0.1
            (let ((map (plist-get plist :map)))
              (when map
                (if (and (plist-p map) (string-list-p (getf map :exclude)))
                    (setf (getf initargs :map) map)
                    (finding :error line ":map must be (:exclude (\"glob\" ...))"))))
            (let ((catalog (plist-get plist :catalog)))
              (when catalog
                (if (and (plist-p catalog)
                         (let ((budget (getf catalog :budget)))
                           (or (null budget) (and (integerp budget) (plusp budget)))))
                    (setf (getf initargs :catalog) catalog)
                    (finding :error line ":catalog must be (:budget <positive integer>)"))))
            ;; :stewards
            (let ((stewards (plist-get plist :stewards)))
              (when stewards
                (if (and (listp stewards) (every #'plist-p stewards))
                    (setf (getf initargs :stewards)
                          (loop for entry in stewards
                                for ns = (getf entry :namespace)
                                for name = (getf entry :steward)
                                for approval = (or (getf entry :approval) :second-reviewer)
                                if (and (stringp ns) (stringp name)
                                        (member approval '(:solo :second-reviewer)))
                                  collect (make-steward-entry :namespace ns :name name
                                                              :approval approval)
                                else do (finding :error (line-of entry)
                                                 "each :stewards entry needs :namespace and ~
                                                  :steward strings, and :approval :solo or ~
                                                  :second-reviewer")))
                    (finding :error line ":stewards must be a list of steward entries"))))
            ;; :authorities
            (let ((authorities (plist-get plist :authorities)))
              (when authorities
                (if (and (listp authorities)
                         (every (lambda (e) (and (plist-p e)
                                                 (stringp (getf e :namespace))
                                                 (stringp (getf e :authority))))
                                authorities))
                    (setf (getf initargs :authorities) authorities)
                    (finding :error line ":authorities must be a list of ~
                                          (:namespace \"NS\" :authority \"example.net,2026\")"))))
            (values (apply #'make-instance 'manifest initargs)
                    (nreverse findings))))))))

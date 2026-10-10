;;;; helpers.lisp — Temporary repositories, document builders, and finding predicates for tests
;;;;
;;;; Read-if: writing a test that needs a corpus on disk

(in-package #:compass.tests)

(defun repository-root ()
  "The root of this repository (the directory of compass.asd)."
  (asdf:system-source-directory "compass"))

(defun call-with-temp-repository (files function)
  "Write FILES, a list of (PATH CONTENT), into a fresh temporary directory, call
FUNCTION with its pathname, and delete the directory afterwards."
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "compass-test-~36r-~d/"
                                        (random (expt 36 8)) (get-universal-time))
                                (uiop:temporary-directory)))))
    (ensure-directories-exist root)
    (unwind-protect
         (progn
           (loop for (path content) in files
                 do (compass.util:write-text-file (compass.util:root-file root path)
                                                  content))
           (funcall function root))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defmacro with-temp-repository ((root files) &body body)
  `(call-with-temp-repository ,files (lambda (,root) ,@body)))

(defun lines (&rest lines)
  (format nil "~{~a~%~}" lines))

(defun doc (&key (id "TEST-0001") (title "A test document") (genre "Plan")
                 (scope "project") (status "Draft") (language "en")
                 (authors '("Tester")) created (extra '())
                 (body (lines "# A test document" "")))
  "The text of a document with the given front-matter. A field given as NIL is
omitted, as CREATED is by default: outside a Git repository, git/derivable
reports it. EXTRA is a list of additional front-matter lines."
  (with-output-to-string (out)
    (format out "---~%")
    (when id (format out "id: ~a~%" id))
    (when title (format out "title: ~a~%" title))
    (when genre (format out "genre: ~a~%" genre))
    (when scope (format out "scope: ~a~%" scope))
    (when language (format out "language: ~a~%" language))
    (when status (format out "status: ~a~%" status))
    (when authors (format out "authors:~%~{  - ~a~%~}" authors))
    (when created (format out "created: ~a~%" created))
    (format out "~{~a~%~}" extra)
    (format out "---~%~a" body)))

(defun check-files (files &key rules skip-unmarked (manifest nil manifest-p) git)
  "Check a temporary repository holding FILES, a Git repository with them
committed if GIT is true. Return the findings and the corpus."
  (funcall (if git #'call-with-git-repository #'call-with-temp-repository)
           (if manifest-p (cons (list "compass.sexp" manifest) files) files)
           (lambda (root)
             (let* ((corpus (load-corpus root :skip-unmarked skip-unmarked))
                    (findings (check-corpus corpus :only rules)))
               (values findings corpus)))))

(defun findings-of (findings rule)
  (remove rule findings :key #'finding-rule :test-not #'string=))

(defun has-finding-p (findings rule &key path line severity)
  (some (lambda (f)
          (and (string= (finding-rule f) rule)
               (or (null path) (equal (finding-path f) path))
               (or (null line) (eql (finding-line f) line))
               (or (null severity) (eq (finding-severity f) severity))))
        findings))

(defun describe-findings (findings)
  (format nil "~{~a~^; ~}"
          (mapcar (lambda (f) (format nil "~a:~a ~a ~a" (finding-path f) (finding-line f)
                                      (finding-rule f) (finding-message f)))
                  findings)))

;;; The command line

(defun run-cli (&rest args)
  "Run compass with ARGS. Return the exit code, standard output, and error output."
  (let* ((out (make-string-output-stream))
         (err (make-string-output-stream))
         (code (let ((*standard-output* out) (*error-output* err))
                 (main args :exit nil))))
    (values code (get-output-stream-string out) (get-output-stream-string err))))

(defun root-arg (root) (format nil "--root=~a" (uiop:native-namestring root)))

;;; Ledgers

(defparameter *ledger-manifest* "(:namespaces (\"TEST\") :doc-directory \"doc/\")"
  "A manifest declaring that the repository owns the TEST namespace, so the ledger
rules apply and numbers can be allocated.")

(defun entry-line (id kind &key draft path host (date "2026-10-09") (by "Tester"))
  "One ledger line."
  (format-ledger-entry (make-ledger-entry :id id :kind kind :draft draft :path path
                                          :host host :date date :by by)))

(defun ledger-file (&rest lines)
  "The text of a TEST ledger holding LINES after its header."
  (format nil "~a~{~a~%~}" (ledger-header '("TEST")) lines))

(defun canonical-doc (id &rest options)
  "A document with the canonical identifier ID, accepted."
  (apply #'doc :id id :status "Accepted" options))

(defun check-with-ledger (files ledger &key rules)
  "Check a repository with the TEST manifest, FILES, and LEDGER (the ledger's
text, or NIL for none). Return the findings and the corpus."
  (check-files (if ledger (cons (list "doc/REGISTRY.sexp" ledger) files) files)
               :rules rules :manifest *ledger-manifest*))

(defun read-file (root path)
  (read-text-file (root-file root path)))

;;; Git repositories

(defun git-in (root &rest arguments)
  "Run Git in ROOT with ARGUMENTS; return its output. Signal on failure."
  (values (run-git root arguments)))

(defun git-status-in (root &rest arguments)
  "Run Git in ROOT with ARGUMENTS; return its exit status, without signalling."
  (nth-value 1 (run-git root arguments :check nil)))

(defun commit-all (root message)
  (git-in root "add" "-A")
  (git-in root "commit" "-q" "--no-verify" "-m" message))

(defun write-file (root path content)
  (write-text-file (root-file root path) content))

(defun call-with-git-repository (files function &key (name "Tester")
                                                     (email "tester@example.net"))
  "Like CALL-WITH-TEMP-REPOSITORY, but the directory is a Git repository whose
first commit holds FILES, on the branch main, with NAME and EMAIL configured."
  (call-with-temp-repository
   files
   (lambda (root)
     (git-in root "init" "-q" "-b" "main")
     (git-in root "config" "user.name" name)
     (git-in root "config" "user.email" email)
     (git-in root "config" "commit.gpgsign" "false")
     (when files (commit-all root "initial"))
     (funcall function root))))

(defmacro with-git-repository ((root files &rest options) &body body)
  `(call-with-git-repository ,files (lambda (,root) ,@body) ,@options))

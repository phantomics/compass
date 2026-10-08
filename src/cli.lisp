;;;; cli.lisp — The compass command: argument parsing, subcommands, and the executable entry point
;;;;
;;;; Read-if: adding a subcommand or option, or changing exit codes
;;;; See: COMPASS-DRAFT-toolchain, COMPASS-DRAFT-toolchain-D19
;;;; Invariant: exit 0 on success, 1 on findings or a failed lookup, 2 on usage or internal error
;;;; Tests: tests/test-cli.lisp

(in-package #:compass.cli)

(defparameter +version+ "0.1.0")

(defvar *build-commit* nil
  "The commit this executable was built from, stamped by build.lisp.")

(define-condition usage-error (error)
  ((message :initarg :message :reader usage-error-message))
  (:report (lambda (c s) (write-string (usage-error-message c) s))))

(defun usage-error (control &rest args)
  (error 'usage-error :message (apply #'format nil control args)))

;;; Arguments

(defun parse-arguments (args options)
  "Split ARGS into positional arguments and an alist of options. OPTIONS is a
list of (NAME KIND), KIND being :flag, :value, or :list (repeatable, and
comma-separated)."
  (let ((positional '()) (values '()) (rest args))
    (loop while rest
          do (let ((arg (pop rest)))
               (cond
                 ((string= arg "--")
                  (setf positional (revappend rest positional) rest nil))
                 ((and (starts-with-p "--" arg) (> (length arg) 2))
                  (let* ((eq-pos (position #\= arg))
                         (name (subseq arg 2 eq-pos))
                         (inline (and eq-pos (subseq arg (1+ eq-pos))))
                         (spec (assoc name options :test #'string=)))
                    (unless spec (usage-error "unknown option --~a" name))
                    (ecase (second spec)
                      (:flag
                       (when inline (usage-error "--~a takes no value" name))
                       (push (cons name t) values))
                      ((:value :list)
                       (let ((value (or inline
                                        (if rest (pop rest)
                                            (usage-error "--~a needs a value" name)))))
                         (if (eq (second spec) :list)
                             (dolist (v (uiop:split-string value :separator ","))
                               (unless (string= v "") (push (cons name v) values)))
                             (push (cons name value) values)))))))
                 ((and (starts-with-p "-" arg) (> (length arg) 1))
                  (usage-error "unknown option ~a" arg))
                 (t (push arg positional)))))
    (values (nreverse positional) (nreverse values))))

(defun option (options name)
  (cdr (assoc name options :test #'string=)))

(defun option-list (options name)
  (loop for (key . value) in options when (string= key name) collect value))

(defun output-format (options)
  (let ((value (or (option options "format") "text")))
    (cond ((string= value "text") :text)
          ((string= value "json") :json)
          (t (usage-error "--format must be text or json, not ~s" value)))))

(defun repository-root (options)
  (let ((given (option options "root")))
    (if given
        (let ((dir (uiop:ensure-directory-pathname
                    (uiop:merge-pathnames* (uiop:parse-native-namestring given)
                                           (uiop:getcwd)))))
          (unless (uiop:directory-exists-p dir)
            (usage-error "--root ~a is not a directory" given))
          (uiop:ensure-directory-pathname (truename dir)))
        (find-repository-root (uiop:getcwd)))))

(defun repository-path (argument root)
  "ARGUMENT, a path on the command line, as a repository-relative path; a
directory's path ends in /."
  (let* ((pathname (uiop:merge-pathnames* (uiop:parse-native-namestring argument)
                                          (uiop:getcwd)))
         (directory (uiop:directory-exists-p (uiop:ensure-directory-pathname pathname))))
    (cond
      (directory
       (let ((relative (relative-path-string (truename directory) root)))
         (if (or (string= relative "") (string= relative "./")) "" relative)))
      ((uiop:file-exists-p pathname)
       (relative-path-string (truename pathname) root))
      (t (usage-error "no such file or directory: ~a" argument)))))

(defun version-string ()
  (format nil "compass ~a (~@[commit ~a, ~]~a ~a, ~a ~a)"
          +version+ *build-commit*
          (lisp-implementation-type) (lisp-implementation-version)
          (string-downcase (software-type)) (string-downcase (machine-type))))

;;; Commands

(defstruct (command) name function synopsis summary options)

(defvar *commands* '())

(defmacro define-command (name (&key synopsis summary options) (args) &body body)
  `(setf *commands*
         (append (remove ,name *commands* :key #'command-name :test #'string=)
                 (list (make-command :name ,name :synopsis ,synopsis :summary ,summary
                                     :options ',options
                                     :function (lambda (,args) ,@body))))))

(defun find-command (name)
  (find name *commands* :key #'command-name :test #'string=))

(define-command "check"
    (:synopsis "check [PATH...] [--root DIR] [--format text|json] [--strict] [--skip-unmarked] [--rule NAME...] [--exclude NAME...]"
     :summary "Check the corpus against the standard; report findings"
     :options (("root" :value) ("format" :value) ("strict" :flag)
               ("skip-unmarked" :flag) ("rule" :list) ("exclude" :list)))
    (args)
  (multiple-value-bind (paths options) (parse-arguments args (command-options (find-command "check")))
    (let* ((format (output-format options))
           (root (repository-root options))
           (only (option-list options "rule"))
           (exclude (option-list options "exclude"))
           (unknown (find-if-not (lambda (pattern)
                                   (some (lambda (rule) (rule-selected-p rule (list pattern) nil))
                                         (list-rules)))
                                 (append only exclude)))
           (selected (mapcar (lambda (p) (repository-path p root)) paths)))
      (when unknown (usage-error "no rule matches ~s; see `compass rules`" unknown))
      (let* ((corpus (load-corpus root :skip-unmarked (option options "skip-unmarked")))
             (findings (check-corpus corpus :only only :exclude exclude
                                            :paths (and selected
                                                        (not (member "" selected
                                                                     :test #'string=))
                                                        selected))))
        (write-findings findings *standard-output* :format format :corpus corpus
                                                   :version +version+)
        (exit-code findings :strict (option options "strict"))))))

(define-command "show"
    (:synopsis "show ID[#ANCHOR] [--root DIR]"
     :summary "Print a document, one of its sections, or a record"
     :options (("root" :value)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "show")))
    (unless (= (length positional) 1) (usage-error "show takes one ID or ID#ANCHOR"))
    (let ((corpus (load-corpus (repository-root options) :skip-unmarked t))
          (reference (first positional)))
      (multiple-value-bind (text path first last) (show corpus reference)
        (cond
          (text
           (format *standard-output* "<!-- compass show ~a: ~a, lines ~a-~a -->~%~a"
                   reference path first last text)
           0)
          (t
           (format *error-output* "compass: ~a is not defined in this corpus~%" reference)
           1))))))

(define-command "index"
    (:synopsis "index [--namespace NS] [--stdout] [--root DIR]"
     :summary "Generate INDEX.md in the document directory"
     :options (("root" :value) ("namespace" :value) ("stdout" :flag)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "index")))
    (when positional (usage-error "index takes no arguments"))
    (let ((corpus (load-corpus (repository-root options) :skip-unmarked t))
          (namespace (option options "namespace")))
      (if (option options "stdout")
          (write-string (generate-index corpus :namespace namespace) *standard-output*)
          (format *standard-output* "Wrote ~a~%" (write-index corpus :namespace namespace)))
      0)))

(define-command "next"
    (:synopsis "next NAMESPACE [--kind document|decision|open-question|memo] [--root DIR]"
     :summary "Preview the next identifier of a kind in a namespace (advisory)"
     :options (("root" :value) ("kind" :value)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "next")))
    (unless (= (length positional) 1) (usage-error "next takes one NAMESPACE"))
    (let* ((namespace (first positional))
           (kind-name (or (option options "kind") "document"))
           (kind (cdr (assoc kind-name '(("document" . :document) ("decision" . :decision)
                                         ("open-question" . :open-question)
                                         ("memo" . :memo))
                             :test #'string=))))
      (unless kind
        (usage-error "--kind must be document, decision, open-question, or memo"))
      (unless (ppcre:scan "^[A-Z][A-Z0-9]*$" namespace)
        (usage-error "~s is not a namespace; namespaces are uppercase, such as COMPASS"
                     namespace))
      (let ((corpus (load-corpus (repository-root options) :skip-unmarked t)))
        (format *standard-output* "~a~%" (next-identifier corpus namespace kind))
        (format *error-output* "compass: advisory: computed from the identifiers defined ~
                                in this working tree; the ledger (v0.2) will be the ~
                                authority~%")
        0))))

(define-command "rules"
    (:synopsis "rules [--format text|json]"
     :summary "List the rules, with their severities and the sections they enforce"
     :options (("format" :value)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "rules")))
    (when positional (usage-error "rules takes no arguments"))
    (let ((rules (list-rules)))
      (ecase (output-format options)
        (:text
         (let ((width (reduce #'max rules :key (lambda (r) (length (rule-name r))))))
           (dolist (rule rules)
             (format *standard-output* "~va  ~7a  ~10a  ~a~%" width (rule-name rule)
                     (string-downcase (symbol-name (rule-severity rule)))
                     (or (rule-section rule) "")
                     (rule-summary rule)))))
        (:json
         (shasht:write-json
          (coerce (mapcar (lambda (rule)
                            (let ((table (make-hash-table :test #'equal)))
                              (setf (gethash "name" table) (rule-name rule)
                                    (gethash "severity" table)
                                    (string-downcase (symbol-name (rule-severity rule)))
                                    (gethash "section" table) (or (rule-section rule) :null)
                                    (gethash "scope" table)
                                    (string-downcase (symbol-name (rule-scope rule)))
                                    (gethash "summary" table) (rule-summary rule))
                              table))
                          rules)
                  'vector)
          *standard-output*)
         (terpri *standard-output*)))
      0)))

(define-command "version"
    (:synopsis "version" :summary "Print the version, build commit, and platform")
    (args)
  (when args (usage-error "version takes no arguments"))
  (format *standard-output* "~a~%" (version-string))
  0)

(defun print-help (stream)
  (format stream "Usage: compass COMMAND [ARGUMENTS]~%~%Commands:~%")
  (dolist (command *commands*)
    (format stream "  ~10a ~a~%" (command-name command) (command-summary command)))
  (format stream "~%Exit status: 0 success; 1 errors found or lookup failed; ~
                  2 usage or internal error.~%"))

(define-command "help"
    (:synopsis "help [COMMAND]" :summary "Show this help, or a command's synopsis")
    (args)
  (cond ((null args) (print-help *standard-output*) 0)
        ((find-command (first args))
         (let ((command (find-command (first args))))
           (format *standard-output* "Usage: compass ~a~%~%~a.~%"
                   (command-synopsis command) (command-summary command))
           0))
        (t (usage-error "unknown command ~s" (first args)))))

;;; Entry point

(defun run (args)
  (cond
    ((null args) (print-help *error-output*) 2)
    ((member (first args) '("-h" "--help") :test #'string=)
     (print-help *standard-output*) 0)
    ((member (first args) '("-V" "--version") :test #'string=)
     (format *standard-output* "~a~%" (version-string)) 0)
    (t
     (let ((command (find-command (first args))))
       (unless command (usage-error "unknown command ~s" (first args)))
       (funcall (command-function command) (rest args))))))

(defun output-closed-p (condition)
  "True if CONDITION reports that standard output was closed by its reader, as
when compass is piped into head."
  (and (typep condition 'stream-error)
       (or #+sbcl (typep condition 'sb-int:broken-pipe)
           (let ((stream (stream-error-stream condition)))
             (or (eq stream *standard-output*)
                 #+sbcl (eq stream sb-sys:*stdout*))))))

(defun main (&optional (args (uiop:command-line-arguments)) &key (exit t))
  "Run the compass command with ARGS. With EXIT (the default), exit the process
with the command's status; otherwise return it."
  (let ((code
          (handler-case
              (prog1 (run args)
                (finish-output *standard-output*))
            (usage-error (e)
              (format *error-output* "compass: ~a~%Run `compass help` for usage.~%" e)
              2)
            #+sbcl
            (sb-sys:interactive-interrupt ()
              (format *error-output* "~&compass: interrupted~%")
              130)
            (stream-error (e)
              (if (output-closed-p e)
                  141                   ; as if terminated by SIGPIPE, silently
                  (progn (format *error-output* "compass: internal error: ~a~%" e)
                         2)))
            (error (e)
              (format *error-output* "compass: internal error: ~a~%" e)
              2))))
    (ignore-errors (finish-output *error-output*))
    (if exit (uiop:quit code nil) code)))

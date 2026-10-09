;;;; build.lisp — Load dependencies under Quicklisp or ocicl, then build or test
;;;;
;;;; Read-if: changing how the executable is built, tested, or stamped with its version
;;;; See: COMPASS-DRAFT-toolchain
;;;; Invariant: runs with --no-userinit, so builds do not depend on ~/.sbclrc

(require :asdf)

(defpackage #:compass-build
  (:use #:cl)
  (:export #:build #:test #:load-compass))

(in-package #:compass-build)

(defparameter *root*
  (uiop:pathname-directory-pathname (or *load-truename* *default-pathname-defaults*))
  "The repository root: the directory containing this file.")

(defun deps ()
  "The dependency manager selected by the DEPS environment variable: ql or ocicl."
  (let ((value (string-downcase (or (uiop:getenv "DEPS") "ql"))))
    (cond ((string= value "ql") :ql)
          ((string= value "ocicl") :ocicl)
          (t (format *error-output* "~&build: DEPS must be ql or ocicl, not ~s~%" value)
             (uiop:quit 2)))))

(defun load-runtime ()
  "Load the selected dependency manager's runtime."
  (ecase (deps)
    (:ql
     (unless (find-package "QL")
       (let ((setup (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
         (unless (probe-file setup)
           (format *error-output* "~&build: Quicklisp not found at ~a~%" setup)
           (uiop:quit 2))
         (load setup))))
    (:ocicl
     (unless (find-package "OCICL-RUNTIME")
       (let ((runtime (merge-pathnames "ocicl/ocicl-runtime.lisp"
                                       (uiop:xdg-data-home))))
         (unless (probe-file runtime)
           (format *error-output* "~&build: ocicl runtime not found at ~a~%" runtime)
           (uiop:quit 2))
         (load runtime)))))
  (asdf:initialize-source-registry
   `(:source-registry (:directory ,*root*) :inherit-configuration)))

(defun load-system (name)
  (if (eq (deps) :ql)
      (uiop:symbol-call :ql :quickload name :silent t)
      (asdf:load-system name)))

(defun git-output (&rest args)
  (ignore-errors
   (string-trim '(#\Space #\Newline #\Return)
                (uiop:run-program (list* "git" "-C" (namestring *root*) args)
                                  :output :string :error-output nil))))

(defun stamp-build ()
  "Record the commit this build comes from in the image."
  (let ((commit (git-output "rev-parse" "--short=12" "HEAD"))
        (dirty (let ((status (git-output "status" "--porcelain"
                                         "--untracked-files=no")))
                 (and status (plusp (length status))))))
    (setf (symbol-value (uiop:find-symbol* "*BUILD-COMMIT*" "COMPASS.CLI"))
          (and commit (plusp (length commit))
               (if dirty (concatenate 'string commit "-dirty") commit)))))

(defun load-compass ()
  (load-runtime)
  (load-system "compass"))

(defun build ()
  "Build bin/compass. The old executable is deleted first: ASDF would otherwise
keep it whenever no source file has changed, even though the commit it records
has, and `compass version` would name the wrong commit."
  (load-compass)
  (stamp-build)
  (let ((executable (merge-pathnames "bin/compass" *root*)))
    (when (probe-file executable)
      (delete-file executable)))
  (asdf:make "compass"))

(defun test ()
  "Run the test suite and exit with its status."
  (load-runtime)
  (load-system "compass/tests")
  (uiop:quit (if (uiop:symbol-call :compass.tests :run-tests) 0 1)))

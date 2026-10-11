;;;; build.lisp — Load dependencies under Quicklisp or ocicl, then build or test
;;;;
;;;; Read-if: changing how the executable is built, tested, or stamped with its version
;;;; See: COMPASS-DRAFT-toolchain
;;;; Invariant: runs with --no-userinit, so builds do not depend on ~/.sbclrc
;;;; Invariant: a definition in a compass package that replaces another fails the build

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

(defun external-dependencies (name)
  "The systems NAME depends on, directly or through other compass systems,
that are not compass systems themselves."
  (let ((found '()))
    (labels ((walk (system)
               (dolist (dependency (asdf:system-depends-on (asdf:find-system system)))
                 (let ((dependency (if (consp dependency) (car (last dependency)) dependency)))
                   (if (uiop:string-prefix-p "compass" (string-downcase dependency))
                       (walk dependency)
                       (pushnew dependency found :test #'equal))))))
      (walk name))
    (nreverse found)))

(defun compass-symbol-p (name)
  "True if NAME, a function name, belongs to a compass package."
  (let ((symbol (if (consp name) (second name) name)))
    (and (symbolp symbol) (symbol-package symbol)
         (uiop:string-prefix-p "COMPASS" (package-name (symbol-package symbol))))))

(defparameter *replacement-warnings*
  '(("SB-KERNEL" "REDEFINITION-WITH-DEFUN" "SB-KERNEL" "REDEFINITION-WARNING-NAME")
    ("SB-KERNEL" "REDEFINITION-WITH-DEFGENERIC" "SB-KERNEL" "REDEFINITION-WARNING-NAME")
    ("SB-INT" "DUPLICATE-DEFINITION" "SB-INT" "DUPLICATE-DEFINITION-NAME"))
  "The SBCL warnings that report a function replacing another, each with the
reader of the name it concerns: one definition replacing another from a
different file, and two definitions in the same file. Macros and methods are
left out: compiling a file and then loading it redefines each of them with the
same definition.")

(defun redefinition-name (condition)
  "The function name CONDITION reports as replaced, or NIL if it is not such a
report. Only SBCL signals these; elsewhere this finds none."
  (or (loop for (class-package class reader-package reader) in *replacement-warnings*
            for class-symbol = (find-symbol class class-package)
            for reader-symbol = (find-symbol reader reader-package)
            when (and class-symbol reader-symbol (find-class class-symbol nil)
                      (typep condition class-symbol) (fboundp reader-symbol))
              return (funcall reader-symbol condition))
      ;; SBCL also reports a function replacing a structure accessor as a plain
      ;; warning, "redefinition of ~S clobbers structure ~:[accessor~;...~]".
      (and (typep condition 'simple-warning)
           (search "clobbers structure"
                   (princ-to-string (simple-condition-format-control condition)))
           (first (simple-condition-format-arguments condition)))))

(defun call-guarding-redefinitions (function)
  "Call FUNCTION, which loads compass systems, and exit 1 if any definition in
a compass package replaced another while they loaded. Two such replacements,
each silent, caused real bugs; Quicklisp muffles the warnings that report them,
so the compass systems themselves are loaded with ASDF, inside this handler."
  (let ((replaced '()))
    (handler-bind ((warning (lambda (condition)
                              (let ((name (redefinition-name condition)))
                                (when (and name (compass-symbol-p name)
                                           (not (member name replaced :test #'equal)))
                                  ;; Reported at once: a replacement within one file is
                                  ;; also a full warning, on which ASDF then stops.
                                  (format *error-output* "~&build: ~s is defined twice: ~a~%"
                                          name condition)
                                  (push name replaced))))))
      (funcall function))
    (when replaced
      (format *error-output* "~&build: ~d definition~:p replaced another while loading; ~
                              give one of each pair another name~%" (length replaced))
      (uiop:quit 1))))

(defun load-system (name)
  "Load the system NAME: its outside dependencies through the selected manager,
then the compass systems with ASDF, failing on a replaced definition."
  (when (eq (deps) :ql)
    (uiop:symbol-call :ql :quickload (external-dependencies name) :silent t))
  (call-guarding-redefinitions (lambda () (asdf:load-system name))))

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

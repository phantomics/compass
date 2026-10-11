;;;; test-repository.lisp — The toolchain reads this repository's own files and finds them conforming

(in-package #:compass.tests)

(def-suite repository :in compass)
(in-suite repository)

(defun repository-markdown (pattern)
  (directory (merge-pathnames pattern (repository-root))))

(test every-front-matter-block-parses
  "Every front-matter block in doc/, templates/, skills/, and Compass.md is within
the YAML subset (COMPASS-DRAFT-toolchain-D18)."
  (dolist (file (append (repository-markdown "doc/*.md")
                        (repository-markdown "templates/*.md")
                        (repository-markdown "skills/*/SKILL.md")
                        (repository-markdown "skills/reference/*.md")
                        (repository-markdown "Compass.md")))
    (let ((document (read-document file :path (namestring file))))
      (is (null (document-load-findings document))
          "~a: ~a" (file-namestring file)
          (describe-findings (document-load-findings document))))))

(test repository-checks-clean
  "This repository's own corpus has no errors."
  (let* ((corpus (load-corpus (repository-root)))
         (findings (check-corpus corpus))
         (errors (remove :warning findings :key #'finding-severity)))
    (is (null errors) (describe-findings errors))
    (is (find "Compass.md" (corpus-documents corpus) :key #'document-path :test #'equal))))

;;; Strings written as format controls

(defparameter *format-control-positions*
  '(("FORMAT" 2) ("ERROR" 1) ("WARN" 1) ("CERROR" 2)
    ("EMIT" 3) ("EMIT-SEVERITY" 4) ("REFUSE" 1) ("NOTE" 2) ("USAGE-ERROR" 1)
    ("YAML-FAIL" 3) ("FINDING" 3) ("FINDING-AT" 3) ("WARN-ABOUT" 2)
    ;; Local functions of the same name in different files.
    ("PROBLEM" 1 2) ("WARNING" 1))
  "Operators whose arguments at the given positions are format controls, which
may continue a line with a tilde and a newline.")

(defun continued-line-p (string)
  "True if STRING continues a line as a format control does: a tilde followed
by a newline."
  (search (coerce '(#\~ #\Newline) 'string) string))

(defun stray-format-strings (form)
  "The strings in FORM that continue a line with a tilde and a newline but are
not in a position where they are used as a format control, or as a rule's
`:summary`, which `define-rule` formats."
  (let ((found '()))
    (labels ((walk (form allowed)
               (cond
                 ((stringp form)
                  (when (and (continued-line-p form) (not allowed)) (push form found)))
                 ((consp form)
                  (let* ((head (and (symbolp (car form)) (symbol-name (car form))))
                         (positions (cdr (assoc head *format-control-positions*
                                                :test #'equal))))
                    (loop for rest = form then (cdr rest)
                          for index from 0
                          while (consp rest)
                          do (walk (car rest)
                                   (or (and (member index positions) t)
                                       ;; The branches of a control chosen by IF.
                                       (and (eq allowed t) (equal head "IF") (>= index 2))
                                       (and (equal head "DEFINE-RULE") (= index 2)
                                            :rule-options))))
                    (when (eq allowed :rule-options)
                      (loop for (key value) on form by #'cddr
                            when (and (eq key :summary) (stringp value))
                              do (setf found (remove value found :test #'eq)))))))))
      (walk form nil))
    found))

(defun read-source-forms (pathname)
  "The top-level forms of the Lisp source file PATHNAME, read in the packages
its IN-PACKAGE forms name."
  (let ((*package* (find-package "COMPASS.TESTS"))
        (*read-eval* nil)
        (forms '()))
    (with-open-file (in pathname :external-format :utf-8)
      (loop for form = (read in nil in)
            until (eq form in)
            do (push form forms)
               (when (and (consp form) (eq (car form) 'in-package))
                 (setf *package* (find-package (second form))))))
    (nreverse forms)))

(test stray-format-strings-are-found
  (is (equal (list (format nil "a ~~~%b"))
             (stray-format-strings `(make-finding :message ,(format nil "a ~~~%b")))))
  (is (null (stray-format-strings `(format nil ,(format nil "a ~~~%b")))))
  (is (null (stray-format-strings `(emit document where ,(format nil "a ~~~%b") x))))
  (is (null (stray-format-strings `(emit d w (if p ,(format nil "a ~~~%b") "c")))))
  (is (stray-format-strings `(if p ,(format nil "a ~~~%b") "c")))
  (is (null (stray-format-strings `(define-rule "x/y" (:severity :error
                                                       :summary ,(format nil "a ~~~%b"))
                                     (corpus))))))

(test no-stray-format-strings
  "No message in the toolchain's source continues a line with a tilde and a newline
outside a format control, where the tilde would be printed."
  (dolist (file (directory (merge-pathnames "src/**/*.lisp" (repository-root))))
    (dolist (form (read-source-forms file))
      (dolist (string (stray-format-strings form))
        (fail "~a: ~s is not a format control, so its ~~ and newline would be printed"
              (file-namestring file) (subseq string 0 (min 60 (length string))))))))

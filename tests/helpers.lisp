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
                 (authors '("Tester")) (extra '()) (body (lines "# A test document" "")))
  "The text of a document with the given front-matter. A field given as NIL is
omitted. EXTRA is a list of additional front-matter lines."
  (with-output-to-string (out)
    (format out "---~%")
    (when id (format out "id: ~a~%" id))
    (when title (format out "title: ~a~%" title))
    (when genre (format out "genre: ~a~%" genre))
    (when scope (format out "scope: ~a~%" scope))
    (when language (format out "language: ~a~%" language))
    (when status (format out "status: ~a~%" status))
    (when authors (format out "authors:~%~{  - ~a~%~}" authors))
    (format out "~{~a~%~}" extra)
    (format out "---~%~a" body)))

(defun check-files (files &key rules skip-unmarked (manifest nil manifest-p))
  "Check a temporary repository holding FILES. Return the findings and the corpus."
  (with-temp-repository (root (if manifest-p
                                  (cons (list "compass.sexp" manifest) files)
                                  files))
    (let* ((corpus (load-corpus root :skip-unmarked skip-unmarked))
           (findings (check-corpus corpus :only rules)))
      (values findings corpus))))

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

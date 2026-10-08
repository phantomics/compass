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

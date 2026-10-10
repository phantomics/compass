;;;; test-git.lisp — Tests for the Git layer

(in-package #:compass.tests)

(def-suite git :in compass)
(in-suite git)

(test git-basics
  (is-true (git-available-p))
  (with-git-repository (root (list (list "a.txt" (lines "one" "two" "three"))
                                   (list "d/b.txt" "b")))
    (is-true (git-repository-p root))
    (is-true (git-has-commits-p root))
    (is (= 40 (length (git-resolve root "HEAD"))))
    (is (null (git-resolve root "no-such-branch")))
    (is (eq :file (git-object-type root "HEAD" "a.txt")))
    (is (eq :directory (git-object-type root "HEAD" "d")))
    (is (null (git-object-type root "HEAD" "missing.txt")))
    (is (equal (lines "one" "two" "three") (git-file-at root "HEAD" "a.txt")))
    (is (null (git-file-at root "HEAD" "missing.txt")))
    (is (equal '("a.txt" "d/b.txt") (sort (git-tracked-files root) #'string<)))
    (is-false (git-shallow-p root))))

(test git-outside-a-repository
  (with-temp-repository (root (list (list "a.txt" "a")))
    (is-false (git-repository-p root))))

(test git-unavailable
  (let ((*git-program* "/nonexistent/compass-test-git"))
    (is-false (git-available-p))
    (signals git-unavailable (run-git (uiop:getcwd) '("--version")))
    (with-temp-repository (root '())
      (is-false (git-repository-p root)))))

(test git-errors
  (with-git-repository (root (list (list "a.txt" "a")))
    (signals git-error (run-git root '("rev-parse" "--verify" "nope")))
    (multiple-value-bind (output status) (run-git root '("rev-parse" "--verify" "nope")
                                                  :check nil)
      (declare (ignore output))
      (is (/= 0 status)))))

(test git-added-lines
  (with-git-repository (root (list (list "a.txt" (lines "one" "two" "three" "four"))))
    (write-file root "a.txt" (lines "one" "TWO" "three" "four" "five" "six"))
    (multiple-value-bind (added all) (git-added-lines root "HEAD" "a.txt")
      (is (equal '(2 5 6) added))
      (is-false all))
    (write-file root "new.txt" (lines "x"))
    (multiple-value-bind (added all) (git-added-lines root "HEAD" "new.txt")
      (is (null added))
      (is-true all))
    (is (equal '() (git-added-lines root "HEAD" "a.txt.missing")))))

(test git-attributes
  (with-git-repository (root (list (list "doc/REGISTRY.sexp" "")))
    (is (equal "unspecified" (git-attribute root "merge" "doc/REGISTRY.sexp")))
    (write-file root ".gitattributes" (lines "doc/REGISTRY.sexp merge=union"))
    (is (equal "union" (git-attribute root "merge" "doc/REGISTRY.sexp")))
    (write-file root ".gitattributes" (lines "*.sexp -merge"))
    (is (equal "unset" (git-attribute root "merge" "doc/REGISTRY.sexp")))))

(test git-identity-and-mailmap
  (with-git-repository (root (list (list "a.txt" "a")) :name "phan" :email "p@example.net")
    (is (equal "phan" (git-identity root)))
    (write-file root ".mailmap" (lines "Ada Lovelace <p@example.net>"))
    (is (equal "Ada Lovelace" (git-identity root)))))

(test git-default-base
  (with-git-repository (root (list (list "a.txt" "a")))
    (is (null (git-default-base root)))
    (let ((*default-bases* '("main")))
      (is (equal "main" (git-default-base root))))))

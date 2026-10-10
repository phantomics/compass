;;;; test-federation.lisp — Tests for check --federation, the federation rules, and the generated index

(in-package #:compass.tests)

(def-suite federation :in compass)
(in-suite federation)

(defun init-git-in (directory)
  "Make DIRECTORY a Git repository with its files in one commit."
  (git-in directory "init" "-q" "-b" "main")
  (git-in directory "config" "user.name" "Tester")
  (git-in directory "config" "user.email" "tester@example.net")
  (git-in directory "config" "commit.gpgsign" "false")
  (commit-all directory "initial"))

(defun alpha-doc (&rest body-lines)
  (doc :id "AAA-DRAFT-alpha" :created "2026-10-09" :extra '("relates-to:" "  - BBB-0001")
       :body (apply #'lines "# Alpha" "" body-lines)))

(defparameter *bravo*
  (doc :id "BBB-0001" :created "2026-10-09" :extra '("decisions:" "  - BBB-D1")
       :body (lines "# Bravo" "" "## Part" "" "### BBB-D1 — Use a ledger" ""
                    "**Status:** Accepted")))

(defun federation-files (&key (alpha (alpha-doc)) (c-manifest nil)
                              (b-manifest "(:namespaces (\"BBB\"))"))
  (append (list (list "a/compass.sexp"
                      (lines "(:namespaces (\"AAA\")"
                             " :federation ((:namespace \"BBB\" :path \"../b\")"
                             "              (:namespace \"CCC\" :path \"../c\")))"))
                (list "a/doc/Plan.A.md" alpha)
                (list "b/compass.sexp" b-manifest)
                (list "b/doc/Plan.B.md" *bravo*)
                (list "b/doc/REGISTRY.sexp"
                      (format nil "~a~a~%" (ledger-header '("BBB"))
                              (format-ledger-entry
                               (make-ledger-entry :id "BBB-0001" :kind :document
                                                  :draft "BBB-DRAFT-bravo"
                                                  :path "doc/Plan.B.md" :date "2026-10-09"
                                                  :by "Tester"))))
                (list "b/src/x.lisp" (lines "(defun frob ())")))
          (and c-manifest (list (list "c/compass.sexp" c-manifest)
                                (list "c/doc/README.md" "# C")))))

(defun federation-check (parent &key (federation t) rules)
  (let ((corpus (load-corpus (merge-pathnames "a/" parent))))
    (when federation (load-federation corpus))
    (values (check-corpus corpus :only rules) corpus)))

(test without-federation-references-are-unverified
  (with-temp-repository (parent (federation-files
                                 :alpha (alpha-doc "[BBB-0001](../../b/doc/Plan.B.md#nothing)")))
    (multiple-value-bind (findings corpus)
        (federation-check parent :federation nil :rules '("ref/" "federation/"))
      (is (null findings) (describe-findings findings))
      (is (= 2 (length (corpus-unverified corpus)))))))

(test federated-references-resolve
  (with-temp-repository (parent (federation-files
                                 :alpha (alpha-doc
                                         "[BBB-0001](../../b/doc/Plan.B.md#part),"
                                         "[BBB-D1](../../b/doc/Plan.B.md#bbb-d1--use-a-ledger),"
                                         "and [the alias](../../b/doc/Plan.B.md).")))
    (multiple-value-bind (findings corpus)
        (federation-check parent :rules '("ref/doc-resolves" "register/"))
      (is (null findings) (describe-findings findings))
      (is (null (corpus-unverified corpus)))
      (is (equal "BBB-0001" (corpus-alias-target corpus "BBB-DRAFT-bravo"))
          "the federated ledger's aliases resolve"))))

(test federated-references-that-do-not-resolve
  (with-temp-repository (parent (federation-files
                                 :alpha (doc :id "AAA-DRAFT-alpha" :created "2026-10-09"
                                             :extra '("relates-to:" "  - BBB-0009")
                                             :body (lines "# Alpha" ""
                                                          "[BBB-0001](../../b/doc/Plan.B.md#nothing),"
                                                          "[BBB-0002](../../b/doc/Plan.B.md), and"
                                                          "[gone](../../b/doc/Gone.md)."))))
    (let ((findings (federation-check parent :rules '("ref/doc-resolves"))))
      (is (= 4 (length findings)) (describe-findings findings))
      (is (search "names BBB-0009, which is not defined" (finding-message (first findings))))
      (is (search "has no heading with the anchor #nothing" (finding-message (second findings))))
      (is (search "the link text names BBB-0002, but ../../b/doc/Plan.B.md declares BBB-0001"
                  (finding-message (third findings))))
      (is (search "the link target ../../b/doc/Gone.md does not exist"
                  (finding-message (fourth findings)))))))

(test federation-path-problems
  (with-temp-repository (parent (federation-files))
    (let ((findings (federation-check parent :rules '("federation/"))))
      (is (= 1 (length findings)))
      (is (has-finding-p findings "federation/path" :path "compass.sexp" :line 3))
      (is (search "the federated repository for CCC, ../c, does not exist"
                  (finding-message (first findings))))))
  (with-temp-repository (parent (federation-files :c-manifest "(:namespaces (\"DDD\"))"))
    (let ((findings (federation-check parent :rules '("federation/"))))
      (is (search "../c is listed for CCC, but its compass.sexp owns DDD"
                  (finding-message (first findings))))))
  (with-temp-repository (parent (federation-files :c-manifest nil))
    (ensure-directories-exist (merge-pathnames "c/" parent))
    (write-file parent "c/notes.txt" "no manifest")
    (let ((findings (federation-check parent :rules '("federation/"))))
      (is (search "../c has no compass.sexp" (finding-message (first findings)))))))

(test federation-namespace-claimed-twice
  (with-temp-repository (parent (federation-files :b-manifest "(:namespaces (\"BBB\" \"AAA\"))"
                                                  :c-manifest "(:namespaces (\"CCC\" \"BBB\"))"))
    (let ((findings (federation-check parent :rules '("federation/namespace"))))
      (is (= 2 (length findings)) (describe-findings findings))
      (is (search "AAA is owned both by this repository and by ../b"
                  (finding-message (first findings))))
      (is (search "BBB is owned by both ../b and ../c" (finding-message (second findings)))))))

(test federated-code-references
  (with-temp-repository (parent (federation-files))
    (init-git-in (merge-pathnames "b/" parent))
    (let ((revision (trim-whitespace (git-in (merge-pathnames "b/" parent)
                                             "rev-parse" "--short" "HEAD"))))
      (write-file parent "a/doc/Plan.A.md"
                  (alpha-doc (format nil "`BBB:src/x.lisp:frob@~a`, `BBB:src/x.lisp:spin@~:*~a`,"
                                     revision)
                             "and `CCC:src/y.lisp:f@abc1234`."))
      (init-git-in (merge-pathnames "a/" parent))
      (multiple-value-bind (findings corpus)
          (federation-check parent :rules '("ref/code-exists"))
        (is (= 1 (length findings)) (describe-findings findings))
        (is (search "src/x.lisp defines no spin" (finding-message (first findings))))
        (is (equal '("CCC:src/y.lisp:f@abc1234") (mapcar #'third (corpus-unverified corpus)))
            "CCC is not loaded")))))

(test check-federation-command
  (with-temp-repository (parent (federation-files))
    (let ((root (merge-pathnames "a/" parent)))
      (multiple-value-bind (code out) (run-cli "check" (root-arg root))
        (is (= 0 code) out)
        (is (search "Did not verify 1 reference" out)))
      (multiple-value-bind (code out) (run-cli "check" "--federation" (root-arg root))
        (is (= 1 code))
        (is (search "compass.sexp:3: error federation/path" out))
        (is (not (search "Did not verify" out))))))
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :created "2026-10-09"))))
    (multiple-value-bind (code out) (run-cli "check" "--federation" (root-arg root))
      (is (= 0 code))
      (is (search "Note: --federation loaded nothing" out)))))

;;; The generated index

(test index-check
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :created "2026-10-09"))))
    (multiple-value-bind (code out) (run-cli "index" "--check" (root-arg root))
      (is (= 1 code))
      (is (search "doc/INDEX.md does not exist; write it with compass index" out)))
    (is (null (check-corpus (load-corpus root) :only '("index/current")))
        "a repository without an index has nothing to keep current")
    (is (= 0 (run-cli "index" (root-arg root))))
    (multiple-value-bind (code out) (run-cli "index" "--check" (root-arg root))
      (is (= 0 code))
      (is (search "doc/INDEX.md is current." out)))
    (is (null (check-corpus (load-corpus root) :only '("index/current"))))
    (write-file root "doc/Plan.B.md" (doc :id "TEST-0002" :created "2026-10-09"))
    (multiple-value-bind (code out) (run-cli "index" "--check" (root-arg root))
      (is (= 1 code))
      (is (search "doc/INDEX.md differs from what compass index would write, from line" out)))
    (let ((findings (check-corpus (load-corpus root) :only '("index/current"))))
      (is (has-finding-p findings "index/current" :path "doc/INDEX.md")))
    ;; Line endings do not matter.
    (is (= 0 (run-cli "index" (root-arg root))))
    (write-file root "doc/INDEX.md"
                (ppcre:regex-replace-all (string #\Newline) (read-file root "doc/INDEX.md")
                                         (coerce '(#\Return #\Newline) 'string)))
    (is (= 0 (run-cli "index" "--check" (root-arg root))))
    (is (= 2 (run-cli "index" "--check" "--stdout" (root-arg root))))))

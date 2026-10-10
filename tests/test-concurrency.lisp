;;;; test-concurrency.lisp — Concurrent allocations on two branches: the conflict, and recovering from it
;;;;
;;;; Read-if: changing the ledger's format, assign, renumber, or the ledger rules
;;;; See: COMPASS-DRAFT-toolchain-D3, COMPASS-DRAFT-toolchain-D22, COMPASS-DRAFT-toolchain-D25

(in-package #:compass.tests)

(def-suite concurrency :in compass)
(in-suite concurrency)

;;; Two people, Alice and Bob, branch from main and each assign a number. The
;;; ledger is what makes the second merge conflict instead of silently
;;; defining one number twice.

(defun concurrency-files (&key attributes)
  (append (list (list "compass.sexp" *ledger-manifest*)
                (list "doc/REGISTRY.sexp"
                      (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.A.md")
                                   (entry-line "TEST-D1" :decision :host "TEST-0001")))
                (list "doc/Plan.A.md"
                      (canonical-doc "TEST-0001" :extra '("decisions:" "  - TEST-D1")
                                                 :body (lines "# Alpha" ""
                                                              "### TEST-D1 — Use a ledger" ""
                                                              "**Status:** Accepted"))))
          (and attributes (list (list ".gitattributes" attributes)))))

(defun proposal (slug &key (records 1) (body-lines '()))
  "An accepted plan TEST-DRAFT-SLUG with RECORDS decisions."
  (let ((id (format nil "TEST-DRAFT-~a" slug)))
    (doc :id id :status "Accepted"
         :extra (if (plusp records)
                    (cons "decisions:" (loop for n from 1 to records
                                             collect (format nil "  - ~a-D~d" id n)))
                    '())
         :body (format nil "# ~:(~a~)~%~{~a~%~}~{~a~%~}" slug
                       (loop for n from 1 to records
                             append (list "" (format nil "### ~a-D~d — Choice ~d" id n n) ""
                                          "**Status:** Accepted"))
                       body-lines))))

(defun allocate-on-branch (root branch path text)
  "On a new BRANCH from main, write the document TEXT at PATH, assign it, and commit."
  (git-in root "checkout" "-q" "-b" branch "main")
  (write-file root path text)
  (multiple-value-bind (code out err) (run-cli "assign" (root-arg root) (file-arg root path))
    (is (= 0 code) "~a: assign failed: ~a~a" branch out err))
  (commit-all root (format nil "~a assigns ~a" branch path)))

(defun race (root &key (alice (list "doc/Plan.B.md" (proposal "beta")))
                       (bob (list "doc/Plan.C.md" (proposal "gamma"))))
  "Alice and Bob each assign from main, and Alice's branch merges first. Leave
Bob's branch checked out, before main is merged into it."
  (allocate-on-branch root "alice" (first alice) (second alice))
  (allocate-on-branch root "bob" (first bob) (second bob))
  (git-in root "checkout" "-q" "main")
  (git-in root "merge" "-q" "--ff-only" "alice")
  (git-in root "checkout" "-q" "bob"))

(defun merge-main (root)
  "Merge main into the current branch; return Git's exit status."
  (git-status-in root "merge" "-q" "--no-edit" "main"))

(defun unmerged-paths (root)
  (remove "" (uiop:split-string (git-in root "diff" "--name-only" "--diff-filter=U")
                                :separator '(#\Newline))
          :test #'string=))

(defun findings-now (root &key base)
  (check-corpus (load-test-corpus root) :base base))

(defun errors-now (root &key base)
  (remove :warning (findings-now root :base base) :key #'finding-severity))

(defun count-matches (needle haystack)
  (loop with start = 0
        for at = (search needle haystack :start2 start)
        while at count t do (setf start (1+ at))))

(defun rules-of (findings)
  (sort (remove-duplicates (mapcar #'finding-rule findings) :test #'string=) #'string<))

;;; 1. Concurrent allocations conflict.

(test concurrent-allocations-conflict
  (with-git-repository (root (concurrency-files))
    (race root)
    (is (/= 0 (merge-main root)))
    (is (equal '("doc/REGISTRY.sexp") (unmerged-paths root))
        "the ledger conflicts; the documents, in different files, do not")
    (let ((errors (errors-now root)))
      (is (has-finding-p errors "ledger/valid" :path "doc/REGISTRY.sexp"))
      (is (search "run compass renumber"
                  (finding-message (first (findings-of errors "ledger/valid"))))))))

;;; 2. Keeping both sides by hand leaves the number allocated twice.

(defun keep-both-sides (root)
  (write-file root "doc/REGISTRY.sexp"
              (strip-conflict-markers (read-file root "doc/REGISTRY.sexp"))))

(test keeping-both-sides-is-caught
  (with-git-repository (root (concurrency-files))
    (race root)
    (merge-main root)
    (keep-both-sides root)
    (let ((errors (errors-now root)))
      (is (equal '("id/unique" "ledger/unique" "register/unique") (rules-of errors))
          (describe-findings errors))
      (is (= 2 (length (findings-of errors "ledger/unique"))) "TEST-0002 and TEST-D2"))))

;;; 3. Keeping both sides, or leaving the markers, and running renumber recovers.

(defun check-recovered (root)
  "The repository after Bob's recovery: Bob's numbers moved, Alice's kept."
  (let ((ledger (read-file root "doc/REGISTRY.sexp")))
    (is (= 1 (count-matches ":id \"TEST-0002\"" ledger)))
    (is (search (entry-line "TEST-0003" :document :draft "TEST-DRAFT-gamma" :path "doc/Plan.C.md"
                                                  :date (today))
                ledger))
    (is (search (entry-line "TEST-D3" :decision :draft "TEST-DRAFT-gamma-D1" :host "TEST-0003"
                                                :date (today))
                ledger)
        "the host moves with the document")
    (is (starts-with-p (git-in root "show" "main:doc/REGISTRY.sexp") ledger)
        "main's ledger is kept, as a prefix"))
  (is (search "id: TEST-0003" (read-file root "doc/Plan.C.md")))
  (is (search "### TEST-D3 — Choice 1" (read-file root "doc/Plan.C.md")))
  (is (search "id: TEST-0002" (read-file root "doc/Plan.B.md")) "Alice's document is untouched")
  (is (search "### TEST-D2 — Choice 1" (read-file root "doc/Plan.B.md")))
  (let ((errors (errors-now root :base "main")))
    (is (null errors) (describe-findings errors))))

(test renumber-recovers-from-markers
  (with-git-repository (root (concurrency-files))
    (git-in root "config" "merge.conflictStyle" "diff3")
    (race root)
    (merge-main root)
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" "--dry-run" (root-arg root))
      (is (= 0 code) "~a" err)
      (is (search "Would renumber against main:" out))
      (is (search "TEST-0002  →  TEST-0003  (document)" out))
      (is (search "TEST-D2    →  TEST-D3  (decision)" out))
      (is (search "conflict markers were removed" out))
      (is (search "<<<<<<<" (read-file root "doc/REGISTRY.sexp")) "a dry run writes nothing"))
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" (root-arg root))
      (is (= 0 code) "~a" err)
      (is (search "Renumbered against main:" out))
      (is (search "compass check finds no errors." out)))
    (check-recovered root)
    (commit-all root "merge main")
    (is (null (errors-now root :base "main")))
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" (root-arg root))
      (is (= 0 code) "~a" err)
      (is (search "Nothing to do." out)))))

(test renumber-recovers-from-both-sides-kept
  (with-git-repository (root (concurrency-files))
    (race root)
    (merge-main root)
    (keep-both-sides root)
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" (root-arg root))
      (declare (ignore out))
      (is (= 0 code) "~a" err))
    (check-recovered root)))

(test renumber-rewrites-only-this-branchs-lines
  (with-git-repository (root (concurrency-files))
    ;; A line Alice wrote that names her TEST-0002 must not become TEST-0003.
    (race root :alice (list "doc/Plan.B.md"
                            (proposal "beta" :body-lines '("" "TEST-DRAFT-beta is this plan."))))
    (merge-main root)
    (write-file root "doc/Plan.C.md"
                (concatenate 'string (read-file root "doc/Plan.C.md")
                             (lines "" "See TEST-0002 for the other plan; TEST-D1, D2 apply.")))
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" (root-arg root))
      (is (= 0 code) "~a" err)
      (is (search "Warning: 1 short reference to the records numbered here" out)
          "the D2 after TEST-D1 may have meant either TEST-D2"))
    (is (search "TEST-0002 is this plan." (read-file root "doc/Plan.B.md")))
    (is (search "See TEST-0003 for the other plan; TEST-D1, D2 apply."
                (read-file root "doc/Plan.C.md"))
        "Bob's line is rewritten; Bob meant his own document")))

;;; 3b. Taking upstream's ledger drops Bob's entries; renumber restores them, without aliases.

(test renumber-after-taking-upstream
  (with-git-repository (root (concurrency-files))
    (race root)
    (merge-main root)
    (git-in root "checkout" "--theirs" "doc/REGISTRY.sexp")
    (is (equal '("id/unique" "ledger/append-only" "register/unique") (rules-of (errors-now root)))
        "Bob's TEST-0002 and TEST-D2 are defined twice, and his ledger lines at HEAD are gone")
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" (root-arg root))
      (is (= 0 code) "~a" err)
      (is (search "TEST-0002 in doc/Plan.C.md had no ledger entry; it becomes TEST-0003, and any provisional alias it had is lost"
                  out)))
    (let ((ledger (read-file root "doc/REGISTRY.sexp")))
      (is (search (entry-line "TEST-0003" :document :path "doc/Plan.C.md" :date (today)) ledger))
      (is (search (entry-line "TEST-D3" :decision :host "TEST-0003" :date (today)) ledger))
      (is (not (search "TEST-DRAFT-gamma" ledger)) "the alias was in the dropped entry"))
    (is (null (errors-now root :base "main")))))

;;; 4. A number typed by hand is not in the ledger.

(test hand-typed-numbers-are-caught
  (with-git-repository (root (concurrency-files))
    (write-file root "doc/Plan.D.md" (canonical-doc "TEST-0007"))
    (let ((errors (errors-now root)))
      (is (equal '("ledger/coverage") (rules-of errors)))
      (is (has-finding-p errors "ledger/coverage" :path "doc/Plan.D.md")))))

;;; 5. Resolving the conflict by editing or dropping a line upstream wrote.

(test resolving-with-ours-is-caught
  (with-git-repository (root (concurrency-files))
    (race root)
    (merge-main root)
    (git-in root "checkout" "--ours" "doc/REGISTRY.sexp")
    (commit-all root "merge main, keeping my ledger")
    (let ((errors (errors-now root :base "main")))
      (is (has-finding-p errors "ledger/append-only" :path "doc/REGISTRY.sexp" :line 6)
          (describe-findings errors))
      (is (has-finding-p errors "id/unique")))
    (multiple-value-bind (code out) (run-cli "check" "--base" "main" (root-arg root))
      (is (= 1 code))
      (is (search "ledger/append-only" out)))))

;;; 6. A union merge driver hides the conflict; the rule catches the driver.

(test union-merge-is-caught
  (with-git-repository (root (concurrency-files :attributes (lines "doc/REGISTRY.sexp merge=union")))
    (race root)
    (is (= 0 (merge-main root)) "the union driver merges without a conflict")
    (is (equal '("id/unique" "ledger/no-union-merge" "ledger/unique" "register/unique")
               (rules-of (errors-now root))))))

;;; 7. Allocations of different kinds still conflict, and renumber may move nothing.

(test different-kinds-still-conflict
  (with-git-repository (root (concurrency-files))
    (race root
          :alice (list "doc/Plan.B.md" (proposal "beta" :records 0))
          :bob (list "doc/Plan.A.md"
                     (canonical-doc "TEST-0001"
                                    :extra '("decisions:" "  - TEST-D1" "  - TEST-DRAFT-a-D1")
                                    :body (lines "# Alpha" "" "### TEST-D1 — Use a ledger" ""
                                                 "**Status:** Accepted" ""
                                                 "### TEST-DRAFT-a-D1 — Another" ""
                                                 "**Status:** Accepted"))))
    (is (/= 0 (merge-main root)))
    (is (equal '("doc/REGISTRY.sexp") (unmerged-paths root)))
    (multiple-value-bind (code out err) (run-cli "renumber" "--base" "main" (root-arg root))
      (is (= 0 code) "~a" err)
      (is (not (search "→" out)) "TEST-0002 and TEST-D2 do not collide"))
    (let ((ledger (read-file root "doc/REGISTRY.sexp")))
      (is (search "\"TEST-0002\"" ledger))
      (is (search "\"TEST-D2\"" ledger))
      (is (not (search "<<<<<<<" ledger))))
    (is (null (errors-now root :base "main")))))

;;; 8. A reference written with the old provisional identifier still resolves, and is flagged.

(test old-provisional-references-are-flagged
  (with-git-repository (root (append (concurrency-files)
                                     (list (list "doc/Plan.B.md" (proposal "beta")))))
    (git-in root "checkout" "-q" "-b" "bob")
    (write-file root "doc/Plan.F.md"
                (doc :id "TEST-DRAFT-phi" :body (lines "# Phi" "" "Builds on TEST-DRAFT-beta-D1.")))
    (commit-all root "bob writes a plan")
    (git-in root "checkout" "-q" "main")
    (is (= 0 (run-cli "assign" (root-arg root) (file-arg root "doc/Plan.B.md"))))
    (commit-all root "assign")
    (git-in root "checkout" "-q" "bob")
    (is (= 0 (merge-main root)) "Bob touched no ledger, so nothing conflicts")
    (let ((findings (findings-now root :base "main")))
      (is (null (remove :warning findings :key #'finding-severity)) (describe-findings findings))
      (is (has-finding-p findings "ref/stale-alias" :path "doc/Plan.F.md" :line 13
                                                    :severity :warning))
      (is (search "TEST-DRAFT-beta-D1 was assigned TEST-D2; write TEST-D2"
                  (finding-message (first (findings-of findings "ref/stale-alias"))))))))

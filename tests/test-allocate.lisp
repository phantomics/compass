;;;; test-allocate.lisp — Tests for allocating numbers: seeding the ledger, assign, next --in, rewriting, and short references

(in-package #:compass.tests)

(def-suite allocate :in compass)
(in-suite allocate)

(defun load-test-corpus (root)
  (load-corpus root :skip-unmarked t))

(defun refusal (function)
  "The message of the ALLOCATION-REFUSED that FUNCTION signals, or NIL."
  (handler-case (progn (funcall function) nil)
    (allocation-refused (e) (allocation-refused-message e))))

(defun file-arg (root path)
  (uiop:native-namestring (root-file root path)))

;;; Seeding the ledger

(defparameter *seed-files*
  (list (list "compass.sexp" *ledger-manifest*)
        (list "doc/Plan.A.md"
              (canonical-doc "TEST-0002"
                             :extra '("decisions:" "  - TEST-D1" "open-questions:" "  - TEST-O1")
                             :body (lines "# A" "" "### TEST-D1 — One" "" "**Status:** Accepted"
                                          "" "### TEST-O1 — Two" "" "Open.")))
        (list "doc/Plan.B.md" (canonical-doc "TEST-0001"))
        (list "doc/Plan.C.md" (doc :id "TEST-DRAFT-gamma"))))

(test seed-plans-every-numbered-identifier
  (with-git-repository (root (append *seed-files*
                                     (list (list "doc/Plan.D.md" (canonical-doc "OTHER-0001")))))
    (let ((allocation (plan-seed (load-test-corpus root) :today "2026-10-09")))
      (is (eq :seed (allocation-command allocation)))
      (is (equal '("TEST-0001" "TEST-0002" "TEST-D1" "TEST-O1")
                 (mapcar #'ledger-entry-id (allocation-entries allocation)))
          "documents first, then each kind, by number; not OTHER, which is not owned")
      (is (equal (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.B.md")
                              (entry-line "TEST-0002" :document :path "doc/Plan.A.md")
                              (entry-line "TEST-D1" :decision :host "TEST-0002")
                              (entry-line "TEST-O1" :open-question :host "TEST-0002"))
                 (allocation-ledger-text allocation)))
      (is (null (allocation-rewrites allocation))))))

(test seed-refusals
  (with-git-repository (root (cons (list "doc/REGISTRY.sexp" (ledger-file)) *seed-files*))
    (is (search "already exists" (refusal (lambda () (plan-seed (load-test-corpus root)))))))
  (with-git-repository (root (cons (list "doc/Plan.E.md"
                                         (canonical-doc "TEST-0005"
                                                        :extra '("decisions:" "  - TEST-D1")
                                                        :body (lines "# E" "### TEST-D1 — Again"
                                                                     "**Status:** Accepted")))
                                   *seed-files*))
    (is (search "TEST-D1 is defined in more than one place"
                (refusal (lambda () (plan-seed (load-test-corpus root)))))))
  (with-git-repository (root (rest *seed-files*))
    (is (search "does not declare the namespaces"
                (refusal (lambda () (plan-seed (load-test-corpus root))))))))

(test init-ledger-command
  (with-git-repository (root *seed-files*)
    (is (= 1 (run-cli "init" (root-arg root))) "plain init refuses: compass.sexp exists")
    (is (= 2 (run-cli "init" "--ledger" "--namespace" "TEST" (root-arg root))))
    (multiple-value-bind (code out) (run-cli "init" "--ledger" "--dry-run" (root-arg root))
      (is (= 0 code))
      (is (search "Would create the ledger with 4 entries" out))
      (is (not (uiop:file-exists-p (root-file root "doc/REGISTRY.sexp")))))
    (is (= 1 (run-cli "check" (root-arg root))) "ledger/coverage, before seeding")
    (multiple-value-bind (code out) (run-cli "init" "--ledger" (root-arg root))
      (is (= 0 code))
      (is (search "Created the ledger with 4 entries" out))
      (is (search "compass check finds no errors." out)))
    (is (= 0 (run-cli "check" (root-arg root))))
    (multiple-value-bind (code out err) (run-cli "init" "--ledger" (root-arg root))
      (is (= 1 code))
      (is (string= "" out))
      (is (search "already exists" err))))
  (with-temp-repository (root *seed-files*)
    (multiple-value-bind (code out err) (run-cli "init" "--ledger" (root-arg root))
      (declare (ignore out))
      (is (= 2 code))
      (is (search "needs a Git repository" err)))))

;;; assign

(defun beta-files (&key (status "Accepted") (gamma-lines '()))
  "A numbered plan TEST-0001, a provisional plan TEST-DRAFT-beta with STATUS and
three records, and a plan that refers to them, followed by GAMMA-LINES."
  (list (list "compass.sexp" *ledger-manifest*)
        (list "doc/REGISTRY.sexp"
              (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.A.md")
                           (entry-line "TEST-D1" :decision :host "TEST-0001")))
        (list "doc/Plan.A.md"
              (canonical-doc "TEST-0001" :extra '("decisions:" "  - TEST-D1")
                                         :body (lines "# Alpha" "" "### TEST-D1 — Use a ledger"
                                                      "" "**Status:** Accepted")))
        (list "doc/Plan.B.md"
              (doc :id "TEST-DRAFT-beta" :status status
                   :extra '("relates-to:" "  - TEST-0001"
                            "decisions:" "  - TEST-DRAFT-beta-D1" "  - TEST-DRAFT-beta-D2"
                            "open-questions:" "  - TEST-DRAFT-beta-O1")
                   :body (lines "# Beta" "" "## Decisions" ""
                                "### TEST-DRAFT-beta-D1 — Use X" "" "**Status:** Accepted" ""
                                "TEST-DRAFT-beta-D1 builds on TEST-D1." ""
                                "### TEST-DRAFT-beta-D2 — Use Y" "" "**Status:** Proposed" ""
                                "## Open Questions" ""
                                "### TEST-DRAFT-beta-O1 — Whether Z" "" "Still open." ""
                                "```" "TEST-DRAFT-beta-D1 in a fence" "```" ""
                                "<!--" "TEST-DRAFT-beta-D2 in a comment" "-->")))
        (list "doc/Plan.C.md"
              (doc :id "TEST-DRAFT-gamma"
                   :extra '("relates-to:" "  - TEST-DRAFT-beta")
                   :body (apply #'lines "# Gamma" ""
                                "As TEST-DRAFT-beta-D1 says; see [the decision](Plan.B.md#test-draft-beta-d1--use-x)."
                                "The question is TEST-DRAFT-beta#test-draft-beta-o1--whether-z."
                                gamma-lines)))
        (list "notes.txt" (lines "Remember TEST-DRAFT-beta-D2."))))

(test assign-plans-numbers-and-rewrites
  (with-git-repository (root (beta-files))
    (let* ((corpus (load-test-corpus root))
           (allocation (plan-assign corpus "doc/Plan.B.md" :today "2026-10-09")))
      (is (equal '(("TEST-DRAFT-beta" "TEST-0002" :document)
                   ("TEST-DRAFT-beta-D1" "TEST-D2" :decision)
                   ("TEST-DRAFT-beta-D2" "TEST-D3" :decision)
                   ("TEST-DRAFT-beta-O1" "TEST-O1" :open-question))
                 (allocation-mapping allocation)))
      (is (equal (list (entry-line "TEST-0002" :document :draft "TEST-DRAFT-beta"
                                                         :path "doc/Plan.B.md")
                       (entry-line "TEST-D2" :decision :draft "TEST-DRAFT-beta-D1"
                                                       :host "TEST-0002")
                       (entry-line "TEST-D3" :decision :draft "TEST-DRAFT-beta-D2"
                                                       :host "TEST-0002")
                       (entry-line "TEST-O1" :open-question :draft "TEST-DRAFT-beta-O1"
                                                            :host "TEST-0002"))
                 (mapcar #'format-ledger-entry (allocation-entries allocation))))
      (is (starts-with-p (read-file root "doc/REGISTRY.sexp")
                         (allocation-ledger-text allocation)))
      (is (equal '(("notes.txt" 1 "Remember TEST-DRAFT-beta-D2."))
                 (allocation-stale allocation)))
      (is (some (lambda (w) (search "no base revision" w)) (allocation-warnings allocation)))
      (let ((rewrites (allocation-rewrites allocation)))
        (is (equal '("doc/Plan.B.md" "doc/Plan.C.md") (mapcar #'rewrite-path rewrites)))
        (is (= 8 (length (rewrite-changed-lines (first rewrites)))))
        (is (= 3 (length (rewrite-changed-lines (second rewrites)))))
        (let ((beta (rewrite-new-text (first rewrites)))
              (gamma (rewrite-new-text (second rewrites))))
          (is (search (lines "id: TEST-0002") beta))
          (is (search (lines "decisions:" "  - TEST-D2" "  - TEST-D3") beta))
          (is (search (lines "### TEST-D2 — Use X") beta))
          (is (search (lines "TEST-D2 builds on TEST-D1.") beta))
          (is (search (lines "### TEST-O1 — Whether Z") beta))
          (is (search (lines "TEST-DRAFT-beta-D1 in a fence") beta) "fenced code is kept")
          (is (search (lines "TEST-DRAFT-beta-D2 in a comment") beta) "comments are kept")
          (is (search (lines "  - TEST-0002") gamma))
          (is (search "As TEST-D2 says; see [the decision](Plan.B.md#test-d2--use-x)." gamma))
          (is (search "The question is TEST-0002#test-o1--whether-z." gamma)))))))

(test assign-command-writes-and-checks-clean
  (with-git-repository (root (beta-files))
    (is (= 0 (run-cli "index" (root-arg root))))
    (multiple-value-bind (code out) (run-cli "assign" "--dry-run" (root-arg root)
                                             (file-arg root "doc/Plan.B.md"))
      (is (= 0 code))
      (is (search "Would assign numbers in doc/Plan.B.md (status Accepted):" out))
      (is (search "TEST-DRAFT-beta-O1  →  TEST-O1  (open question)" out))
      (is (search "Would rewrite 11 lines in 2 documents" out))
      (is (search "notes.txt:1  Remember TEST-DRAFT-beta-D2." out))
      (is (search "This was a dry run" out))
      (is (search "id: TEST-DRAFT-beta" (read-file root "doc/Plan.B.md"))))
    (multiple-value-bind (code out) (run-cli "assign" (root-arg root)
                                             (file-arg root "doc/Plan.B.md"))
      (is (= 0 code))
      (is (search "Appended 4 entries to the ledger." out))
      (is (search "compass check finds no errors." out)))
    (is (search "id: TEST-0002" (read-file root "doc/Plan.B.md")))
    (is (search "TEST-0002" (read-file root "doc/INDEX.md")) "the index is regenerated")
    (multiple-value-bind (findings) (check-corpus (load-test-corpus root))
      (is (notany (lambda (f) (eq :error (finding-severity f))) findings)
          (describe-findings findings))
      (is (null (findings-of findings "ref/stale-alias"))))
    ;; The old identifiers still resolve.
    (multiple-value-bind (code out err) (run-cli "show" "TEST-DRAFT-beta-D1" (root-arg root))
      (declare (ignore err))
      (is (= 0 code))
      (is (search "### TEST-D2 — Use X" out)))
    (multiple-value-bind (code out err) (run-cli "assign" (root-arg root)
                                                 (file-arg root "doc/Plan.B.md"))
      (is (= 1 code))
      (is (string= "" out))
      (is (search "already has a number and defines no provisional record" err)))))

(test assign-refuses-unaccepted-documents
  (with-git-repository (root (beta-files :status "Proposed"))
    (let ((corpus (load-test-corpus root)))
      (is (search "has the status Proposed"
                  (refusal (lambda () (plan-assign corpus "doc/Plan.B.md")))))
      (let ((allocation (plan-assign corpus "doc/Plan.B.md" :force t)))
        (is (= 4 (length (allocation-mapping allocation))))
        (is (some (lambda (w) (search "assigned with --force" w))
                  (allocation-warnings allocation))))
      (is (search "not a document of this corpus"
                  (refusal (lambda () (plan-assign corpus "doc/Plan.Z.md")))))
      (is (search "already has a number"
                  (refusal (lambda () (plan-assign corpus "doc/Plan.A.md"))))))))

(test assign-refuses-a-broken-ledger
  (flet ((attempt (ledger)
           (with-git-repository (root (cons (list "doc/REGISTRY.sexp" ledger)
                                            (remove "doc/REGISTRY.sexp" (beta-files)
                                                    :key #'first :test #'string=)))
             (refusal (lambda () (plan-assign (load-test-corpus root) "doc/Plan.B.md"))))))
    (is (search "the ledger has 1 error"
                (attempt (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.A.md")
                                      (entry-line "TEST-D1" :decision :host "TEST-0001")
                                      "======="))))
    (is (search "allocates TEST-D1 more than once; run compass renumber"
                (attempt (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.A.md")
                                      (entry-line "TEST-D1" :decision :host "TEST-0001")
                                      (entry-line "TEST-D1" :decision :host "TEST-0001"
                                                                      :by "Someone else")))))))

(test assign-refuses-while-short-references-remain
  (with-git-repository (root (beta-files :gamma-lines '("" "TEST-DRAFT-beta-D1 and D2 settle it.")))
    (let* ((corpus (load-test-corpus root))
           (message (refusal (lambda () (plan-assign corpus "doc/Plan.B.md")))))
      (is (search "1 short reference would change meaning" message))
      (is (search "doc/Plan.C.md:18:24  D2  (probably TEST-DRAFT-beta-D2)" message))
      (let ((allocation (plan-assign corpus "doc/Plan.B.md" :force t)))
        (is (some (lambda (w) (search "1 short reference to the records numbered here" w))
                  (allocation-warnings allocation)))
        (is (search "TEST-D2 and D2 settle it."
                    (rewrite-new-text (second (allocation-rewrites allocation))))
            "a short reference is never rewritten")))
    (multiple-value-bind (code out err) (run-cli "assign" (root-arg root)
                                                 (file-arg root "doc/Plan.B.md"))
      (declare (ignore out))
      (is (= 1 code))
      (is (search "or assign with --force" err)))
    (multiple-value-bind (code out) (run-cli "assign" "--force" (root-arg root)
                                             (file-arg root "doc/Plan.B.md"))
      (is (= 0 code))
      (is (search "Warning: 1 short reference" out)))))

(test assign-numbers-records-added-to-a-numbered-document
  (with-git-repository (root (list (list "compass.sexp" *ledger-manifest*)
                                   (list "doc/REGISTRY.sexp"
                                         (ledger-file
                                          (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                                            :path "doc/Plan.A.md")
                                          (entry-line "TEST-D1" :decision :draft "TEST-DRAFT-alpha-D1"
                                                                          :host "TEST-0001")))
                                   (list "doc/Plan.A.md"
                                         (canonical-doc
                                          "TEST-0001"
                                          :extra '("decisions:" "  - TEST-D1" "  - TEST-DRAFT-alpha-D2")
                                          :body (lines "# Alpha" "" "### TEST-D1 — Old" ""
                                                       "**Status:** Accepted" ""
                                                       "### TEST-DRAFT-alpha-D2 — New" ""
                                                       "**Status:** Accepted")))))
    (let ((corpus (load-test-corpus root)))
      (is (null (check-corpus corpus)) (describe-findings (check-corpus corpus)))
      (is (equal "TEST-DRAFT-alpha-D3" (next-provisional-record corpus "doc/Plan.A.md" :decision)))
      (let ((allocation (plan-assign corpus "doc/Plan.A.md" :today "2026-10-09")))
        (is (equal '(("TEST-DRAFT-alpha-D2" "TEST-D2" :decision)) (allocation-mapping allocation)))
        (is (equal (list (entry-line "TEST-D2" :decision :draft "TEST-DRAFT-alpha-D2"
                                                         :host "TEST-0001"))
                   (mapcar #'format-ledger-entry (allocation-entries allocation))))))))

(test assign-skips-draft-memos
  (with-git-repository (root (list (list "compass.sexp" *ledger-manifest*)
                                   (list "doc/REGISTRY.sexp" (ledger-file))
                                   (list "doc/Memo.Notes.md"
                                         (doc :id "TEST-DRAFT-notes" :genre "Memo" :status "Current"
                                              :scope "component"
                                              :extra '("memos:" "  - TEST-DRAFT-notes-M1"
                                                       "  - TEST-DRAFT-notes-M2")
                                              :body (lines "# Notes: Memos" "" "## Memos" ""
                                                           "### TEST-DRAFT-notes-M1 — Unsettled" ""
                                                           "**Status:** Draft"
                                                           "**Read-if:** changing the thing"
                                                           "**Basis:** decided in TEST-DRAFT-notes; observed" ""
                                                           "### TEST-DRAFT-notes-M2 — Settled" ""
                                                           "**Status:** Current"
                                                           "**Read-if:** changing the thing"
                                                           "**Basis:** decided in TEST-DRAFT-notes; observed")))))
    (let ((allocation (plan-assign (load-test-corpus root) "doc/Memo.Notes.md")))
      (is (equal '(("TEST-DRAFT-notes" "TEST-0001" :document)
                   ("TEST-DRAFT-notes-M2" "TEST-M1" :memo))
                 (allocation-mapping allocation))))
    (is (= 0 (run-cli "assign" (root-arg root) (file-arg root "doc/Memo.Notes.md"))))
    (let ((findings (check-corpus (load-test-corpus root))))
      (is (null (remove :warning findings :key #'finding-severity))
          (describe-findings findings))
      (is (search "### TEST-DRAFT-notes-M1 — Unsettled" (read-file root "doc/Memo.Notes.md"))))))

(test assign-and-next-need-git-and-a-manifest
  (with-temp-repository (root (beta-files))
    (multiple-value-bind (code out err) (run-cli "assign" (root-arg root)
                                                 (file-arg root "doc/Plan.B.md"))
      (declare (ignore out))
      (is (= 2 code))
      (is (search "needs a Git repository" err))))
  (with-git-repository (root (rest (beta-files)))
    (is (search "does not declare the namespaces"
                (refusal (lambda () (plan-assign (load-test-corpus root) "doc/Plan.B.md")))))))

;;; next

(test next-in-a-document
  (with-git-repository (root (beta-files))
    (let ((corpus (load-test-corpus root)))
      (is (equal "TEST-DRAFT-beta-D3" (next-provisional-record corpus "doc/Plan.B.md" :decision)))
      (is (equal "TEST-DRAFT-beta-O2"
                 (next-provisional-record corpus "doc/Plan.B.md" :open-question)))
      (is (equal "TEST-DRAFT-beta-M1" (next-provisional-record corpus "doc/Plan.B.md" :memo)))
      (is (equal "TEST-DRAFT-a-D1" (next-provisional-record corpus "doc/Plan.A.md" :decision))
          "a numbered document with no alias takes a slug from its file name"))
    (multiple-value-bind (code out) (run-cli "next" "--in" (file-arg root "doc/Plan.B.md")
                                             "--kind" "decision" (root-arg root))
      (is (= 0 code))
      (is (equal (lines "TEST-DRAFT-beta-D3") out)))
    (is (= 2 (run-cli "next" "--in" (file-arg root "doc/Plan.B.md") "--kind" "document"
                      (root-arg root))))
    (is (= 2 (run-cli "next" "TEST" "--in" (file-arg root "doc/Plan.B.md") "--kind" "decision"
                      (root-arg root))))
    ;; After assign, the document's alias keeps its records' numbering going.
    (is (= 0 (run-cli "assign" (root-arg root) (file-arg root "doc/Plan.B.md"))))
    (is (equal "TEST-DRAFT-beta-D3"
               (next-provisional-record (load-test-corpus root) "doc/Plan.B.md" :decision)))
    (multiple-value-bind (code out err) (run-cli "next" "TEST" "--kind" "decision" (root-arg root))
      (is (= 0 code))
      (is (equal (lines "TEST-D4") out))
      (is (search "a preview, from the ledger" err)))))

(test next-in-a-document-slugs
  (with-temp-repository (root (list (list "doc/Plan.AgentWorkflow.md" (canonical-doc "TEST-0001"))
                                    (list "doc/Plan.Other.md"
                                          (doc :id "TEST-DRAFT-agent-workflow"))))
    (let ((corpus (load-test-corpus root)))
      (is (equal "TEST-DRAFT-agent-workflow-2-D1"
                 (next-provisional-record corpus "doc/Plan.AgentWorkflow.md" :decision))
          "a slug another document uses is not reused")
      (is (search "not a document"
                  (refusal (lambda () (next-provisional-record corpus "doc/Nope.md" :decision))))))))

;;; Rewriting

(defun mapping-table (&rest pairs)
  (let ((table (make-hash-table :test #'equal)))
    (loop for (old new) on pairs by #'cddr do (setf (gethash old table) new))
    table))

(test rewrite-whole-identifiers-only
  (let ((table (mapping-table "TEST-DRAFT-a" "TEST-0002" "TEST-DRAFT-a-D1" "TEST-D2")))
    (is (string= "TEST-D2 and TEST-DRAFT-a-D10, in TEST-0002."
                 (rewrite-line "TEST-DRAFT-a-D1 and TEST-DRAFT-a-D10, in TEST-DRAFT-a." table)))
    (is (string= "D1, and TEST-DRAFT-ab" (rewrite-line "D1, and TEST-DRAFT-ab" table)))
    (is (string= "(TEST-D2)" (rewrite-line "(TEST-DRAFT-a-D1)" table)))))

(test rewrites-keep-line-endings-and-respect-eligibility
  (let ((crlf (format nil "---~c~%id: TEST-DRAFT-a~c~%title: A~c~%genre: Plan~c~%scope: project~c~%status: Draft~c~%---~c~%# A~c~%TEST-DRAFT-a here.~c~%TEST-DRAFT-a there."
                      #\Return #\Return #\Return #\Return #\Return #\Return #\Return #\Return
                      #\Return)))
    (with-temp-repository (root (list (list "doc/Plan.A.md" crlf)))
      (let* ((corpus (load-test-corpus root))
             (all (first (plan-rewrites corpus '(("TEST-DRAFT-a" . "TEST-0002")))))
             (some (first (plan-rewrites corpus '(("TEST-DRAFT-a" . "TEST-0002"))
                                         :eligible (lambda (path line)
                                                     (declare (ignore path))
                                                     (= line 9))))))
        (is (equal '(2 9 10) (rewrite-changed-lines all)))
        (is (search (format nil "id: TEST-0002~c~%" #\Return) (rewrite-new-text all)))
        (is (ends-with-p "TEST-0002 there." (rewrite-new-text all)) "no final newline is added")
        (is (= (count #\Newline crlf) (count #\Return (rewrite-new-text all))))
        (is (equal '(9) (rewrite-changed-lines some)))
        (is (search "id: TEST-DRAFT-a" (rewrite-new-text some)))))))

;;; Short references

(defun shorts-in (line)
  (mapcar (lambda (item) (destructuring-bind (s e letter serial owner) item
                           (list (subseq line s e) (format nil "~a~a" letter serial) owner)))
          (line-short-references line)))

(test short-references-in-a-line
  (is (equal '(("D2" "D2" "TEST-DRAFT-a") ("D3" "D3" "TEST-DRAFT-a"))
             (shorts-in "See TEST-DRAFT-a-D1, D2 and D3.")))
  (is (equal '(("D6" "D6" "TEST")) (shorts-in "TEST-D4–D6 settle it.")))
  (is (equal '(("O4" "O4" "TEST-DRAFT-b") ("O5" "O5" "TEST-DRAFT-b"))
             (shorts-in "O4 and O5 of TEST-DRAFT-b remain.")))
  (is (equal '(("O4" "O4" "TEST-DRAFT-b"))
             (shorts-in "O4 of [TEST-DRAFT-b](Plan.B.md) remains.")))
  (is (equal '(("D6" "D6" nil)) (shorts-in "As D6 says.")))
  (is (null (shorts-in "`D6` in code, issue #D6, a/D6, M1x, D0, and <!-- D6 -->."))))

(defparameter *short-files*
  (list (list "doc/Plan.A.md"
              (canonical-doc "TEST-0001" :extra '("decisions:" "  - TEST-D1")
                                         :body (lines "# Alpha" "### TEST-D1 — One"
                                                      "**Status:** Accepted" ""
                                                      "D1 is settled.")))
        (list "doc/Plan.B.md"
              (doc :id "TEST-DRAFT-beta"
                   :extra '("relates-to:" "  - TEST-0001" "decisions:" "  - TEST-DRAFT-beta-D1")
                   :body (lines "# Beta" "### TEST-DRAFT-beta-D1 — Two" "**Status:** Proposed" ""
                                "D1 replaces nothing; M7 is a table label."
                                "As O1 and O2 of"
                                "TEST-DRAFT-gamma decided.")))))

(test short-record-rule
  (let ((findings (check-files *short-files* :rules '("ref/short-record"))))
    (is (= 4 (length findings)) (describe-findings findings))
    (is (has-finding-p findings "ref/short-record" :path "doc/Plan.A.md" :line 17
                                                   :severity :warning))
    (is (search "probably TEST-D1" (finding-message (first findings))))
    (is (has-finding-p findings "ref/short-record" :path "doc/Plan.B.md" :line 19))
    (is (search "probably TEST-DRAFT-beta-D1" (finding-message (second findings))))
    (is (search "O1 is a short reference to a record; write its full identifier, probably TEST-DRAFT-gamma-O1"
                (finding-message (third findings))))
    (is (has-finding-p findings "ref/short-record" :path "doc/Plan.B.md" :line 20)))
  ;; Through the ledger: a bare D1 in a numbered document means its record.
  (let ((findings (check-with-ledger
                   (list (list "doc/Plan.A.md"
                               (canonical-doc "TEST-0001" :extra '("decisions:" "  - TEST-D1")
                                                          :body (lines "# Alpha" "### TEST-D1 — One"
                                                                       "**Status:** Accepted" ""
                                                                       "Here D1 holds."))))
                   (ledger-file (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                                  :path "doc/Plan.A.md")
                                (entry-line "TEST-D1" :decision :draft "TEST-DRAFT-alpha-D1"
                                                                :host "TEST-0001"))
                   :rules '("ref/short-record"))))
    (is (= 1 (length findings)))
    (is (search "probably TEST-D1" (finding-message (first findings))))))

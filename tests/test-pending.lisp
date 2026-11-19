;;;; test-pending.lisp — Tests for the listing of what is waiting for a number and the pending command: groups, agreement with assign, files not yet migrated, text, and JSON

(in-package #:compass.tests)

(def-suite pending :in compass)
(in-suite pending)

(defun pending-files (&key (manifest *ledger-manifest*) (ledger t))
  "A repository holding a document for each group of compass pending, one in a
namespace it does not own, one with nothing provisional, and two files without
front-matter. MANIFEST is compass.sexp's text, or NIL for none; LEDGER, the
ledger's text, T for one that records the numbered documents, or NIL for none."
  (append
   (and manifest (list (list "compass.sexp" manifest)))
   (and ledger
        (list (list "doc/REGISTRY.sexp"
                    (if (eq ledger t)
                        (ledger-file
                         (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                           :path "doc/Plan.A.md")
                         (entry-line "TEST-D1" :decision :host "TEST-0001")
                         (entry-line "TEST-0002" :document :draft "TEST-DRAFT-notes"
                                                           :path "doc/Memo.Notes.md")
                         (entry-line "TEST-0003" :document :path "doc/Plan.Done.md"))
                        ledger))))
   (list
    ;; Ready: a numbered document with one provisional record.
    (list "doc/Plan.A.md"
          (canonical-doc "TEST-0001"
                         :extra '("decisions:" "  - TEST-D1" "  - TEST-DRAFT-alpha-D2")
                         :body (lines "# Alpha" "" "### TEST-D1 — Old" "" "**Status:** Accepted"
                                      "" "### TEST-DRAFT-alpha-D2 — New" ""
                                      "**Status:** Accepted")))
    ;; Ready: a provisional document, one of whose records is only Proposed.
    (list "doc/Plan.B.md"
          (doc :id "TEST-DRAFT-beta" :status "Accepted"
               :extra '("decisions:" "  - TEST-DRAFT-beta-D1" "  - TEST-DRAFT-beta-D2"
                        "open-questions:" "  - TEST-DRAFT-beta-O1")
               :body (lines "# Beta" "" "### TEST-DRAFT-beta-D1 — Use X" ""
                            "**Status:** Accepted" "" "### TEST-DRAFT-beta-D2 — Use Y" ""
                            "**Status:** Proposed" "" "### TEST-DRAFT-beta-O1 — Whether Z" ""
                            "Still open.")))
    ;; Blocked: a short reference to a record it would number.
    (list "doc/Plan.C.md"
          (doc :id "TEST-DRAFT-gamma" :status "Accepted"
               :extra '("decisions:" "  - TEST-DRAFT-gamma-D1")
               :body (lines "# Gamma" "" "### TEST-DRAFT-gamma-D1 — Use W" ""
                            "**Status:** Accepted" "" "D1 settles it.")))
    ;; Waiting for its status, with a short reference shown as information.
    (list "doc/Plan.D.md"
          (doc :id "TEST-DRAFT-delta" :status "Draft"
               :extra '("decisions:" "  - TEST-DRAFT-delta-D1")
               :body (lines "# Delta" "" "### TEST-DRAFT-delta-D1 — Use V" ""
                            "**Status:** Proposed" "" "D1 is not settled.")))
    ;; Waiting for its memos: a numbered host whose only provisional record is Draft.
    (list "doc/Memo.Notes.md"
          (doc :id "TEST-0002" :genre "Memo" :status "Current" :scope "component"
               :extra '("memos:" "  - TEST-DRAFT-notes-M1")
               :body (lines "# Notes: Memos" "" "## Memos" ""
                            "### TEST-DRAFT-notes-M1 — Unsettled" "" "**Status:** Draft"
                            "**Read-if:** changing the thing" "**Basis:** observed")))
    ;; Not listed: numbered with nothing provisional, and another namespace.
    (list "doc/Plan.Done.md" (canonical-doc "TEST-0003"))
    (list "doc/Plan.Other.md" (doc :id "OTHER-DRAFT-other" :status "Accepted"))
    ;; Not yet migrated.
    (list "doc/notes/Old.md" (lines "# Old notes" "" "Written before Compass."))
    (list "doc/Design.md" (lines "# Design" "" "Also before.")))))

(defun pending-of (listing)
  "The documents of LISTING as (ID GROUP), in order."
  (mapcar (lambda (p) (list (document-id (pending-document-document p))
                            (pending-document-group p)))
          (pending-listing-documents listing)))

(defun pending-entry-of (listing id)
  (find id (pending-listing-documents listing)
        :key (lambda (p) (document-id (pending-document-document p))) :test #'string=))

(test pending-groups-documents-as-assign-would
  "Each document holding a provisional identifier in an owned namespace is
listed once, in path order, in the group assign's checks place it in; a
numbered document with nothing provisional, and one in another namespace, are
not listed."
  (with-git-repository (root (pending-files))
    (let ((listing (list-pending (load-test-corpus root))))
      (is (equal '("TEST") (pending-listing-namespaces listing)))
      (is (null (pending-listing-corpus-blockers listing)))
      (is (equal '(("TEST-0002" :waiting) ("TEST-0001" :ready) ("TEST-DRAFT-beta" :ready)
                   ("TEST-DRAFT-gamma" :blocked) ("TEST-DRAFT-delta" :waiting))
                 (pending-of listing))))))

(test pending-ready-documents-and-flags
  "A ready document has no blockers; its counts include the document's own
identifier when provisional; a record assign would number whose own status is
not accepted is flagged."
  (with-git-repository (root (pending-files))
    (let* ((listing (list-pending (load-test-corpus root)))
           (alpha (pending-entry-of listing "TEST-0001"))
           (beta (pending-entry-of listing "TEST-DRAFT-beta")))
      (is (null (pending-document-blockers alpha)))
      (is (equal '((:decision . 1)) (pending-counts (pending-document-document alpha))))
      (is (null (pending-document-flagged alpha)))
      (is (equal '((:document . 1) (:decision . 2) (:open-question . 1))
                 (pending-counts (pending-document-document beta))))
      (is (equal '("TEST-DRAFT-beta-D2")
                 (mapcar #'record-id (pending-document-flagged beta)))))))

(test pending-blocked-and-waiting-documents
  "A blocked document carries the blockers assign would refuse with; a waiting
one says why it waits and shows its other blockers as information."
  (with-git-repository (root (pending-files))
    (let* ((listing (list-pending (load-test-corpus root)))
           (gamma (pending-entry-of listing "TEST-DRAFT-gamma"))
           (delta (pending-entry-of listing "TEST-DRAFT-delta"))
           (notes (pending-entry-of listing "TEST-0002")))
      (is (equal '(:short-references) (blocker-kinds (pending-document-blockers gamma))))
      (is (search "1 short reference would change meaning"
                  (blocker-message (first (pending-document-blockers gamma)))))
      (is (eq :status (pending-document-reason delta)))
      (is (equal '(:short-references) (blocker-kinds (pending-document-blockers delta)))
          "the status is the reason, not a blocker shown")
      (is (eq :draft-memos (pending-document-reason notes)))
      (is (null (pending-document-blockers notes)))
      (is (equal '((:memo . 1)) (pending-counts (pending-document-document notes)))
          "a Draft memo is counted, though assign skips it"))))

(test pending-agrees-with-assign
  "assign numbers every ready document, and refuses every blocked one with the
first blocker listed (COMPASS-D79)."
  (with-git-repository (root (pending-files))
    (let* ((corpus (load-test-corpus root))
           (listing (list-pending corpus)))
      (dolist (p (pending-listing-documents listing))
        (let ((path (document-path (pending-document-document p))))
          (case (pending-document-group p)
            (:ready
             (is (null (refusal (lambda () (plan-assign corpus path)))) "~a is ready" path))
            (:blocked
             (is (string= (blocker-message (first (pending-document-blockers p)))
                          (refusal (lambda () (plan-assign corpus path))))
                 "~a is blocked" path))
            (:waiting
             (is (refusal (lambda () (plan-assign corpus path))) "~a waits" path))))))))

(test pending-ready-only
  "With READY, only the ready documents are listed, and no unmarked files."
  (with-git-repository (root (pending-files))
    (let ((listing (list-pending (load-test-corpus root) :ready t)))
      (is (equal '(("TEST-0001" :ready) ("TEST-DRAFT-beta" :ready)) (pending-of listing)))
      (is (null (pending-listing-unmarked listing))))))

(test pending-lists-files-not-yet-migrated
  "Files without front-matter are listed by path, in order, unless a namespace
is given (COMPASS-D83)."
  (with-git-repository (root (pending-files))
    (let ((corpus (load-test-corpus root)))
      (is (equal '("doc/Design.md" "doc/notes/Old.md")
                 (pending-listing-unmarked (list-pending corpus))))
      (let ((listing (list-pending corpus :namespace "TEST")))
        (is (null (pending-listing-unmarked listing)))
        (is (= 5 (length (pending-listing-documents listing)))))
      (let ((listing (list-pending corpus :namespace "OTHER")))
        (is (null (pending-listing-namespaces listing)) "a namespace not owned lists nothing")
        (is (null (pending-listing-documents listing)))))))

(test pending-with-a-broken-ledger
  "A ledger with errors is a corpus-wide blocker: every document whose status
assign accepts is blocked, without blockers of its own; drafts still wait."
  (with-git-repository (root (pending-files
                              :ledger (ledger-file
                                       (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                                         :path "doc/Plan.A.md")
                                       "=======")))
    (let ((listing (list-pending (load-test-corpus root))))
      (is (equal '(:ledger-errors) (blocker-kinds (pending-listing-corpus-blockers listing))))
      (is (eq :blocked (pending-document-group (pending-entry-of listing "TEST-DRAFT-beta"))))
      (is (null (pending-document-blockers (pending-entry-of listing "TEST-DRAFT-beta"))))
      (is (eq :waiting (pending-document-group (pending-entry-of listing "TEST-DRAFT-delta")))))))

(test pending-without-a-git-name
  "A Git without user.name blocks every document whose status assign accepts."
  (with-git-repository (root (pending-files))
    (git-in root "config" "user.name" "")
    (let ((listing (list-pending (load-test-corpus root))))
      (is (equal '(:no-git-name) (blocker-kinds (pending-listing-corpus-blockers listing))))
      (is (equal '(:waiting :blocked :blocked :blocked :waiting)
                 (mapcar #'second (pending-of listing)))))))

(test pending-without-namespaces
  "A manifest without :namespaces leaves only the files not yet migrated, with
the blocker that says why."
  (dolist (manifest (list "(:doc-directory \"doc/\")" nil))
    (with-git-repository (root (pending-files :manifest manifest :ledger nil))
      (let ((listing (list-pending (load-test-corpus root))))
        (is (equal '(:no-namespaces)
                   (blocker-kinds (pending-listing-corpus-blockers listing))))
        (is (null (pending-listing-namespaces listing)))
        (is (null (pending-listing-documents listing)))
        (is (equal '("doc/Design.md" "doc/notes/Old.md")
                   (pending-listing-unmarked listing)))))))

;;; The command

(defun joined (&rest lines)
  "LINES joined by newlines, without a final one, to match a partial last line."
  (format nil "~{~a~^~%~}" lines))

(defun occurrences (part text)
  (loop for start = 0 then (+ found (length part))
        for found = (search part text :start2 start)
        while found count t))

(test pending-command-text
  "compass pending lists the groups in order, each document with its counts,
flags, blockers, and the reason it waits, then the files not yet migrated and
a summary; it exits 0 whatever it lists."
  (with-git-repository (root (pending-files))
    (multiple-value-bind (code out err) (run-cli "pending" (root-arg root))
      (is (= 0 code))
      (is (string= "" err))
      (is (search (joined "Ready to assign (2):"
                         "  TEST-0001  doc/Plan.A.md  Accepted"
                         "    1 decision"
                         "  TEST-DRAFT-beta  doc/Plan.B.md  Accepted"
                         "    the document, 2 decisions, 1 open question; TEST-DRAFT-beta-D2 is Proposed"
                         "Blocked (1):"
                         "  TEST-DRAFT-gamma  doc/Plan.C.md  Accepted"
                         "    the document, 1 decision"
                         "    1 short reference would change meaning once these records are numbered; write it as full identifiers first (or assign with --force):"
                         "      doc/Plan.C.md:")
                  out)
          out)
      (is (search (joined "Waiting for acceptance (2):"
                         "  TEST-0002  doc/Memo.Notes.md  Current"
                         "    1 memo"
                         "    waits for its memos: the memo is Draft, which assign skips"
                         "  TEST-DRAFT-delta  doc/Plan.D.md  Draft"
                         "    the document, 1 decision"
                         "    waits for its status: Draft is not one assign accepts"
                         "    1 short reference would change meaning")
                  out)
          out)
      (is (search (lines "Not yet migrated (2):" "  doc/Design.md" "  doc/notes/Old.md" ""
                         "5 documents hold provisional identifiers: 2 ready, 1 blocked, 2 waiting;"
                         "2 files are not yet migrated.")
                  out)
          out))))

(test pending-command-options
  "--ready prints only the ready group and the summary; --namespace leaves out
the files not yet migrated, and naming a namespace not owned is a failed
lookup."
  (with-git-repository (root (pending-files))
    (multiple-value-bind (code out) (run-cli "pending" "--ready" (root-arg root))
      (is (= 0 code))
      (is (search "Ready to assign (2):" out))
      (is (not (search "Blocked" out)))
      (is (not (search "Waiting" out)))
      (is (not (search "Not yet migrated" out)))
      (is (search "5 documents hold provisional identifiers" out)))
    (multiple-value-bind (code out) (run-cli "pending" "--namespace" "TEST" (root-arg root))
      (is (= 0 code))
      (is (search "Blocked (1):" out))
      (is (not (search "Not yet migrated (2):" out))))
    (multiple-value-bind (code out err) (run-cli "pending" "--namespace" "OTHER" (root-arg root))
      (is (= 1 code))
      (is (string= "" out))
      (is (search "OTHER is not a namespace this repository owns; it owns TEST" err)))
    (is (= 2 (run-cli "pending" "doc/Plan.A.md" (root-arg root))))
    (is (= 2 (run-cli "pending" "--format" "xml" (root-arg root))))))

(test pending-command-json
  "The JSON lists the namespaces, corpus-wide blockers, each document with its
group, counts, records, flags, blockers, and reason, the files not yet migrated,
and a summary of the whole listing, even with --ready."
  (with-git-repository (root (pending-files))
    (multiple-value-bind (code out) (run-cli "pending" "--format" "json" (root-arg root))
      (is (= 0 code))
      (let* ((json (shasht:read-json out))
             (documents (gethash "documents" json))
             (beta (find "TEST-DRAFT-beta" documents :key (lambda (d) (gethash "id" d))
                                                     :test #'equal))
             (delta (find "TEST-DRAFT-delta" documents :key (lambda (d) (gethash "id" d))
                                                       :test #'equal)))
        (is (equal "compass" (gethash "tool" json)))
        (is (equalp #("TEST") (gethash "namespaces" json)))
        (is (= 0 (length (gethash "blockers" json))))
        (is (= 5 (length documents)))
        (is (equal "ready" (gethash "group" beta)))
        (is (equal "doc/Plan.B.md" (gethash "path" beta)))
        (is (equal "TEST" (gethash "namespace" beta)))
        (is (= 2 (gethash "decision" (gethash "counts" beta))))
        (is (= 3 (length (gethash "records" beta))) "the document's own identifier is not a record")
        (is (equalp #("TEST-DRAFT-beta-D2") (gethash "flagged" beta)))
        (is (equal "waiting" (gethash "group" delta)))
        (is (equal "status" (gethash "reason" delta)))
        (is (equal "short-references" (gethash "kind" (aref (gethash "blockers" delta) 0))))
        (is (eq t (gethash "forcible" (aref (gethash "blockers" delta) 0))))
        (is (equalp #("doc/Design.md" "doc/notes/Old.md") (gethash "unmarked" json)))
        (let ((summary (gethash "summary" json)))
          (is (equal '(5 2 1 2 2)
                     (mapcar (lambda (k) (gethash k summary))
                             '("documents" "ready" "blocked" "waiting" "unmarked")))))))
    (multiple-value-bind (code out) (run-cli "pending" "--ready" "--format" "json" (root-arg root))
      (is (= 0 code))
      (let ((json (shasht:read-json out)))
        (is (= 2 (length (gethash "documents" json))))
        (is (= 0 (length (gethash "unmarked" json))))
        (is (= 1 (gethash "blocked" (gethash "summary" json))))))))

(test pending-command-corpus-blockers-and-nothing
  "A corpus-wide blocker is printed once, before the groups; a manifest without
:namespaces says to add them; with nothing pending, one line says so."
  (with-git-repository (root (pending-files
                              :ledger (ledger-file
                                       (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                                         :path "doc/Plan.A.md")
                                       "=======")))
    (multiple-value-bind (code out) (run-cli "pending" (root-arg root))
      (is (= 0 code))
      (is (starts-with-p "Blocking every assignment: the ledger has 1 error" out))
      (is (= 1 (occurrences "the ledger has" out)))
      (is (search "Blocked (3):" out))))
  (with-git-repository (root (pending-files :manifest "(:doc-directory \"doc/\")" :ledger nil))
    (multiple-value-bind (code out) (run-cli "pending" (root-arg root))
      (is (= 0 code))
      (is (search "add :namespaces to compass.sexp" out))
      (is (search "Not yet migrated (2):" out))
      (is (search "No document holds a provisional identifier." out))))
  (with-git-repository (root (list (list "compass.sexp" *ledger-manifest*)
                                   (list "doc/REGISTRY.sexp"
                                         (ledger-file (entry-line "TEST-0001" :document
                                                                  :path "doc/Plan.A.md")))
                                   (list "doc/Plan.A.md" (canonical-doc "TEST-0001"))))
    (multiple-value-bind (code out) (run-cli "pending" (root-arg root))
      (is (= 0 code))
      (is (string= (lines "Nothing is waiting for a number.") out)))))

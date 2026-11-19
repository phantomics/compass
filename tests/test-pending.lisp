;;;; test-pending.lisp — Tests for the listing of what is waiting for a number: its groups, its agreement with assign, and the files not yet migrated

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

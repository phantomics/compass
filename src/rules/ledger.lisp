;;;; ledger.lisp — Rules for the allocation ledger and for references to its aliases
;;;;
;;;; Read-if: changing how the ledger is checked, or what counts as covered by it
;;;; See: COMPASS-DRAFT-toolchain-D1, COMPASS-DRAFT-toolchain-D3, COMPASS-DRAFT-toolchain-D22
;;;; Invariant: no ledger rule runs unless the manifest declares the namespaces the repository owns
;;;; Invariant: without Git, the rules that need it record a note instead of a finding
;;;; Tests: tests/test-ledger.lisp, tests/test-concurrency.lisp

(in-package #:compass.rules)

(defun ledger-rules-apply-p (corpus)
  "True if the repository has a manifest that declares the namespaces it owns."
  (and (manifest-path (corpus-manifest corpus))
       (manifest-namespaces (corpus-manifest corpus))
       t))

(defun ledger-line (entry) (or (ledger-entry-line entry) 1))

(define-rule "ledger/unique" (:severity :error :scope :corpus :section "§13"
                              :summary "No identifier or alias is listed twice in the ledger")
    (corpus)
  (let ((ledger (corpus-ledger corpus))
        (seen-ids (make-hash-table :test #'equal))
        (seen-aliases (make-hash-table :test #'equal)))
    (when (and ledger (ledger-rules-apply-p corpus))
      (dolist (entry (ledger-entries ledger))
        (let ((earlier (gethash (ledger-entry-id entry) seen-ids)))
          (if earlier
              (emit (ledger-path ledger) (ledger-line entry)
                    "~a is already allocated on line ~a; a number is allocated once ~
                     (after a merge conflict, run compass renumber)"
                    (ledger-entry-id entry) (ledger-line earlier))
              (setf (gethash (ledger-entry-id entry) seen-ids) entry)))
        (let* ((alias (ledger-entry-draft entry))
               (earlier (and alias (gethash alias seen-aliases))))
          (cond (earlier
                 (emit (ledger-path ledger) (ledger-line entry)
                       "the alias ~a was already given to ~a on line ~a"
                       alias (ledger-entry-id earlier) (ledger-line earlier)))
                (alias (setf (gethash alias seen-aliases) entry))))))))

(define-rule "ledger/coverage" (:severity :error :scope :corpus :section "§13"
                                :summary "Every canonical identifier defined here is in the ~
                                          ledger, and no assigned provisional identifier is ~
                                          still defined")
    (corpus)
  (when (ledger-rules-apply-p corpus)
    (let ((ledger (corpus-ledger corpus)))
      (dolist (definition (canonical-definitions corpus))
        (destructuring-bind (id document where kind) definition
          (declare (ignore kind))
          (let ((identifier (parse-identifier id)))
            (when (and (corpus-owned-namespace-p corpus (identifier-namespace identifier))
                       (null (ledger-entry-for ledger id)))
              (if ledger
                  (emit document where
                        "~a is not in the ledger (~a); numbers are allocated with ~
                         compass assign, which records them there"
                        id (ledger-path ledger))
                  (emit document where
                        "~a has a number, but this repository has no ledger (~a); create ~
                         one with compass init --ledger, which records the identifiers ~
                         already in use"
                        id (corpus-ledger-path corpus)))))))
      (when ledger
        (dolist (definition (provisional-definitions corpus))
          (destructuring-bind (id document where) definition
            (let ((entry (ledger-alias-entry ledger id)))
              (when entry
                (emit document where
                      "~a was assigned ~a (~a line ~a); write ~a here"
                      id (ledger-entry-id entry) (ledger-path ledger)
                      (ledger-line entry) (ledger-entry-id entry))))))))))

(define-rule "ledger/owned-namespace" (:severity :error :scope :corpus :section "§5, §13"
                                       :summary "The ledger and the canonical identifiers ~
                                                 defined here are in namespaces this ~
                                                 repository owns")
    (corpus)
  (when (ledger-rules-apply-p corpus)
    (let ((owned (manifest-namespaces (corpus-manifest corpus)))
          (ledger (corpus-ledger corpus)))
      (when ledger
        (dolist (entry (ledger-entries ledger))
          (let ((namespace (identifier-namespace (ledger-entry-identifier entry))))
            (unless (member namespace owned :test #'string=)
              (emit (ledger-path ledger) (ledger-line entry)
                    "~a is in the ~a namespace, which compass.sexp does not list under ~
                     :namespaces" (ledger-entry-id entry) namespace)))))
      (dolist (definition (canonical-definitions corpus))
        (destructuring-bind (id document where kind) definition
          (declare (ignore kind))
          (let ((namespace (identifier-namespace (parse-identifier id))))
            (unless (member namespace owned :test #'string=)
              (emit document where
                    "~a is in the ~a namespace, which this repository does not own; ~
                     numbers in it are allocated by the repository that does"
                    id namespace))))))))

(defun git-rules-root (corpus rule-name)
  "The repository root if Git can be used there; otherwise NIL, after noting
that RULE-NAME did not run."
  (let ((root (corpus-root corpus)))
    (cond ((not (git-available-p))
           (note corpus "~a did not run: Git was not found" rule-name) nil)
          ((not (repository-usable-p corpus root))
           (note corpus "~a did not run: not a Git repository" rule-name) nil)
          (t root))))

(define-rule "ledger/append-only" (:severity :error :scope :corpus :section "§13"
                                   :summary "The ledger at the base revision is a prefix of ~
                                             the ledger now")
    (corpus)
  (when (ledger-rules-apply-p corpus)
    (let ((root (git-rules-root corpus "ledger/append-only"))
          (path (corpus-ledger-path corpus))
          (ledger (corpus-ledger corpus)))
      (when root
        (let ((base (or *check-base* (and (git-has-commits-p root) "HEAD"))))
          (when base
            (let ((old (git-file-at root base path)))
              (cond
                ((null old))
                ((null ledger)
                 (emit path 1 "the ledger was deleted; at ~a it allocates ~a ~
                               identifier~:p, which must never be reused"
                       base (length (parse-ledger-text old))))
                ((starts-with-p old (ledger-text ledger)))
                (t
                 (emit path (first-difference old (ledger-text ledger))
                       "this line of the ledger at ~a was changed, moved, or removed; the ~
                        ledger is append-only (after a merge conflict, run compass ~
                        renumber)" base))))))))))

(define-rule "ledger/no-union-merge" (:severity :error :scope :corpus :section "§13"
                                      :summary "No merge driver is set on the ledger that ~
                                                would hide a conflict")
    (corpus)
  (when (and (ledger-rules-apply-p corpus) (corpus-ledger corpus))
    (let ((root (git-rules-root corpus "ledger/no-union-merge"))
          (path (corpus-ledger-path corpus)))
      (when root
        (let ((driver (git-attribute root "merge" path)))
          (unless (member driver '("unspecified" "unset" "set" "text" "binary")
                          :test #'string=)
            (emit path 1 "Git merges this ledger with merge=~a (.gitattributes), which ~
                          would combine concurrent allocations without a conflict; remove ~
                          the attribute" driver)))))))

;;; References written with an alias

(defparameter *aliasable-fields*
  '("relates-to" "supersedes" "superseded-by" "glossary" "decisions" "open-questions"
    "memos"))

(define-rule "ref/stale-alias" (:severity :warning :section "§9, §13" :front-matter nil
                                :summary "References use canonical identifiers, not ~
                                          provisional ones the ledger has assigned")
    (document corpus)
  (let ((ledger (corpus-ledger corpus)))
    (when ledger
      (flet ((stale (where alias)
               (let ((entry (ledger-alias-entry ledger alias)))
                 (emit document where "~a was assigned ~a; write ~a"
                       alias (ledger-entry-id entry) (ledger-entry-id entry)))))
        (when (document-front-matter document)
          (dolist (field *aliasable-fields*)
            (let ((node (document-field-node document field)))
              (dolist (item (cond ((yaml-scalar-p node) (list node))
                                  ((yaml-sequence-p node) (yaml-sequence-items node))))
                (let ((value (node-string item)))
                  (when (and value (ledger-alias-entry ledger value))
                    (stale item value)))))))
        (let ((kinds (document-line-kinds document))
              (lines (document-lines document))
              (headings (make-hash-table)))
          (dolist (record (document-records document))
            (setf (gethash (location-line record) headings) (record-id record)))
          (loop for index from 0 below (length lines)
                for line-number = (1+ index)
                when (member (aref kinds index) '(:text :heading))
                  do (dolist (alias (remove-duplicates
                                     (find-identifiers-in-text (aref lines index))
                                     :test #'string=))
                       (when (and (ledger-alias-entry ledger alias)
                                  (not (equal alias (gethash line-number headings))))
                         (stale line-number alias)))))))))

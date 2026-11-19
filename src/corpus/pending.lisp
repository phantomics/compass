;;;; pending.lisp — What is waiting for a number: documents holding provisional identifiers, grouped by whether assign would number them, and files not yet migrated
;;;;
;;;; Read-if: changing what compass pending lists, or how it groups a document
;;;; See: COMPASS-DRAFT-toolchain-D30, COMPASS-D79, COMPASS-D80, COMPASS-D83
;;;; Invariant: listing writes nothing; a document is ready only when plan-assign would number it
;;;; Tests: tests/test-pending.lisp

(in-package #:compass.corpus)

(defstruct (pending-document)
  document
  group                                 ; :ready, :blocked, or :waiting
  reason                                ; why a :waiting document waits: :status or :draft-memos
  blockers                              ; the document's own BLOCKERs; for :waiting, as information
  flagged)                              ; records assign would number whose own status is not accepted

(defstruct (pending-listing)
  namespaces                            ; the namespaces listed
  corpus-blockers                       ; BLOCKERs of every assignment, reported once
  documents                             ; PENDING-DOCUMENTs, in path order
  unmarked)                             ; paths of files without front-matter, in order

(defun provisional-records (document)
  "DOCUMENT's records whose identifiers are provisional, Draft memos included."
  (remove-if-not (lambda (record) (identifier-provisional-p (record-identifier record)))
                 (document-records document)))

(defun holds-provisional-p (document)
  (let ((identifier (document-identifier document)))
    (or (identifier-provisional-p identifier)
        (provisional-records document))))

(defun pending-counts (document)
  "How many provisional identifiers of each kind DOCUMENT holds, its own and its
records', Draft memos included, as (KIND . N) in the ledger's order of kinds."
  (let ((counts (make-hash-table)))
    (when (identifier-provisional-p (document-identifier document))
      (incf (gethash :document counts 0)))
    (dolist (record (provisional-records document))
      (incf (gethash (record-kind record) counts 0)))
    (loop for kind in *ledger-kinds*
          for n = (gethash kind counts)
          when n collect (cons kind n))))

(defun flagged-records (document)
  "The records assign would number in DOCUMENT whose own status is not one at
which a document is numbered, such as a Proposed decision."
  (let ((to-number (mapcar #'first (identifiers-to-number document))))
    (remove-if-not (lambda (record)
                     (let ((status (record-field record "Status")))
                       (and (member (record-id record) to-number :test #'string=)
                            status
                            (not (member status +accepted-statuses+ :test #'string=)))))
                   (document-records document))))

(defun pending-entry (corpus document corpus-wide)
  "DOCUMENT's PENDING-DOCUMENT, given CORPUS-WIDE, the corpus's blockers."
  (let* ((blockers (document-blockers corpus document))
         (status-p (member (document-status document) +accepted-statuses+ :test #'equal))
         (nothing-p (find :nothing-to-number blockers :key #'blocker-kind)))
    (flet ((entry (group &key reason (shown blockers) flagged)
             (make-pending-document :document document :group group :reason reason
                                    :blockers shown :flagged flagged)))
      (cond ((not status-p)
             (entry :waiting :reason :status
                             :shown (remove :status blockers :key #'blocker-kind)))
            (nothing-p
             (entry :waiting :reason :draft-memos
                             :shown (remove nothing-p blockers)))
            ((or blockers corpus-wide)
             (entry :blocked))
            (t
             (entry :ready :flagged (flagged-records document)))))))

(defun list-pending (corpus &key namespace ready)
  "What in CORPUS is waiting for a number (COMPASS-DRAFT-toolchain-D30), as a
PENDING-LISTING: every document of the repository in a namespace it owns, or in
NAMESPACE alone, that holds a provisional identifier, grouped as assign would
decide (COMPASS-D79); and, unless NAMESPACE or READY is given, the files skipped
for having no front-matter (COMPASS-D83). With READY, only ready documents."
  (let* ((corpus-wide (corpus-blockers corpus))
         (owned (and (not (find :no-namespaces corpus-wide :key #'blocker-kind))
                     (manifest-namespaces (corpus-manifest corpus))))
         (namespaces (if namespace
                         (and (member namespace owned :test #'string=) (list namespace))
                         owned))
         (documents
           (loop for document in (sort (copy-list (corpus-documents corpus)) #'string<
                                       :key #'document-path)
                 for identifier = (document-identifier document)
                 when (and identifier
                           (identifier-document-p identifier)
                           (member (identifier-namespace identifier) namespaces
                                   :test #'string=)
                           (holds-provisional-p document))
                   collect (pending-entry corpus document corpus-wide))))
    (make-pending-listing
     :namespaces namespaces
     :corpus-blockers corpus-wide
     :documents (if ready
                    (remove :ready documents :key #'pending-document-group :test-not #'eq)
                    documents)
     :unmarked (and (not namespace) (not ready)
                    (sort (copy-list (corpus-skipped corpus)) #'string<)))))

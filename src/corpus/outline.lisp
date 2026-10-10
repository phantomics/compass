;;;; outline.lisp — The outline of a document: its headings, anchors, and line ranges
;;;;
;;;; Read-if: changing what `compass outline` reports
;;;; See: COMPASS-DRAFT-toolchain-D21
;;;; Invariant: line ranges agree with `compass show ID#anchor`
;;;; Tests: tests/test-corpus.lisp

(in-package #:compass.corpus)

(defstruct (outline-entry)
  level text anchor start end record)

(defstruct (outline)
  id path title genre status total-lines front-matter-end focus record entries
  (alias nil))                          ; the alias REFERENCE used, if any

(defun section-record (document section)
  "The record whose heading is SECTION, or NIL."
  (find (location-line section) (document-records document) :key #'location-line))

(defun document-outline (corpus reference)
  "The OUTLINE of what REFERENCE names: a document, the host of a record, or,
for \"ID#anchor\", one section and its subsections. NIL if it is not defined.
An alias in the ledger is followed to the identifier it was assigned."
  (multiple-value-bind (id anchor) (split-reference reference)
    (let* ((document (find-document corpus id))
           (record (and (null document) (find-record corpus id)))
           (host (or document (and record (record-document record))))
           (target (and (null host) (corpus-alias-target corpus id))))
      (when target
        (let ((outline (document-outline corpus (if anchor
                                                    (format nil "~a#~a" target anchor)
                                                    target))))
          (when outline (setf (outline-alias outline) id))
          (return-from document-outline outline)))
      (when host
        (let* ((sections (document-sections host))
               (root (and anchor document
                          (find anchor sections :key #'section-anchor :test #'string=))))
          (unless (and anchor document (null root))
            (let ((selected (if root
                                (remove-if-not
                                 (lambda (s) (<= (location-line root) (location-line s)
                                                 (section-end-line root)))
                                 sections)
                                sections)))
              (make-outline
               :id (or (document-id host) id)
               :path (document-path host)
               :title (document-title host)
               :genre (document-genre host)
               :status (document-status host)
               :total-lines (length (document-lines host))
               :front-matter-end (and (document-has-front-matter-p host)
                                      (> (document-body-start-line host) 1)
                                      (1- (document-body-start-line host)))
               :focus (or (and root anchor) (and record (record-anchor record)))
               :record (and record (record-id record))
               :entries
               (mapcar (lambda (section)
                         (let ((start (location-line section)))
                           (make-outline-entry
                            :level (section-level section)
                            :text (trim-whitespace (strip-inline-markup (section-text section)))
                            :anchor (section-anchor section)
                            :start start
                            :end (trim-trailing-blank-lines host start
                                                            (section-end-line section))
                            :record (let ((r (section-record host section)))
                                      (and r (record-id r))))))
                       selected)))))))))

;;;; refs.lisp — Inbound references: everything in the corpus that points at an identifier
;;;;
;;;; Read-if: changing what `compass refs` finds, or how a reference is classified
;;;; See: COMPASS-DRAFT-toolchain-D21
;;;; Invariant: each source line is reported once, under the most specific kind that applies
;;;; Invariant: fenced code and HTML comments are not searched, since they hold examples and guidance
;;;; Tests: tests/test-corpus.lisp

(in-package #:compass.corpus)

;;; Kinds, from most to least specific:
;;;   :relation  a front-matter relation (relates-to, supersedes, superseded-by, glossary)
;;;   :register  a register listing (decisions, open-questions, memos) in a document
;;;              that amends the record rather than defining it
;;;   :link      a link whose destination is the target, or whose text is its identifier
;;;   :basis     a memo record's **Basis:** naming the target
;;;   :mention   the identifier in prose, without a link

(defstruct (inbound-reference)
  kind path line column field text source)

(defparameter *relation-fields* '("relates-to" "supersedes" "superseded-by" "glossary"))

(defparameter *excerpt-length* 120)

(defun excerpt (string)
  (let ((s (trim-whitespace (substitute #\Space #\Tab string))))
    (if (> (length s) *excerpt-length*)
        (concatenate 'string (subseq s 0 (1- *excerpt-length*)) "…")
        s)))

(defun field-value-nodes (document field)
  "The scalar nodes of FIELD in DOCUMENT's front-matter."
  (let ((node (document-field-node document field)))
    (cond ((and (yaml-scalar-p node) (node-string node)) (list node))
          ((yaml-sequence-p node)
           (remove-if-not #'node-string (yaml-sequence-items node)))
          (t '()))))

(defun find-references (corpus reference)
  "The inbound references to REFERENCE (\"ID\" or \"ID#anchor\") in CORPUS, as a
list of INBOUND-REFERENCEs in path and line order. Second and third values are
what REFERENCE names (a document, record, or section) and the document holding
it, or NIL if it is not defined."
  (multiple-value-bind (id anchor) (split-reference reference)
    (let* ((anchor (and anchor (plusp (length anchor)) anchor))
           (document (find-document corpus id))
           (record (and (null document) (find-record corpus id)))
           (host (or document (and record (record-document record))))
           (target-path (and host (document-path host)))
           (target-fragment (or anchor (and record (record-anchor record))))
           (whole-document-p (and document (null anchor)))
           (counted (make-hash-table :test #'equal))
           (results '()))
      (labels ((add (kind source-document line column field text)
                 (let ((path (document-path source-document)))
                   (setf (gethash (cons path line) counted) t)
                   (push (make-inbound-reference :kind kind :path path :line line
                                                 :column column :field field
                                                 :text (excerpt text)
                                                 :source (document-id source-document))
                         results)))
               (counted-p (source-document line)
                 (gethash (cons (document-path source-document) line) counted))
               (names-target-p (text)
                 (if anchor
                     (search reference text)
                     (member id (find-identifiers-in-text text) :test #'string=)))
               (link-to-target-p (source-document link)
                 (multiple-value-bind (kind path fragment)
                     (link-destination source-document (link-target link))
                   (let ((fragment (and fragment (plusp (length fragment)) fragment)))
                     (or (string= (trim-whitespace (strip-inline-markup (link-text link)))
                                  reference)
                         (and (eq kind :local) target-path
                              (string= path target-path)
                              (if target-fragment
                                  (equal fragment target-fragment)
                                  ;; Links within the target document to its own
                                  ;; sections are not inbound references.
                                  (not (eq source-document host)))))))))
        (dolist (source (corpus-documents corpus))
          (unless anchor
            ;; Front-matter relations
            (dolist (field *relation-fields*)
              (dolist (node (field-value-nodes source field))
                (when (string= (node-string node) id)
                  (add :relation source (yaml-node-line node) (yaml-node-column node)
                       field (format nil "~a: ~a" field id)))))
            ;; Register listings that amend the record
            (unless (document-record source id)
              (dolist (kind (register-kinds))
                (dolist (node (field-value-nodes source (register-kind-field kind)))
                  (when (string= (node-string node) id)
                    (add :register source (yaml-node-line node) (yaml-node-column node)
                         (register-kind-field kind)
                         (format nil "~a: ~a" (register-kind-field kind) id)))))))
          ;; Links
          (dolist (link (document-links source))
            (when (link-to-target-p source link)
              (add :link source (location-line link) (location-column link)
                   (link-target link)
                   (format nil "[~a](~a)" (link-text link) (link-target link)))))
          ;; Memo bases
          (unless anchor
            (dolist (memo (document-records source))
              (let ((entry (and (eq (record-kind memo) :memo)
                                (record-field-entry memo "Basis"))))
                (when (and entry (not (counted-p source (field-entry-line entry)))
                           (names-target-p (field-entry-value entry)))
                  (add :basis source (field-entry-line entry) nil (record-id memo)
                       (field-entry-value entry))))))
          ;; Mentions in prose
          (unless (and whole-document-p (eq source host))
            (let ((kinds (document-line-kinds source))
                  (lines (document-lines source)))
              (loop for index from 0 below (length lines)
                    for line-number = (1+ index)
                    for line = (aref lines index)
                    when (and (member (aref kinds index) '(:text :heading))
                              (not (counted-p source line-number))
                              (not (and record (eq source host)
                                        (= line-number (location-line record))))
                              (names-target-p line))
                      do (add :mention source line-number
                              (let ((p (search (if anchor reference id) line)))
                                (and p (1+ p)))
                              nil line)))))
        (multiple-value-bind (definition definition-document) (resolve corpus reference)
          (values (sort results (lambda (a b)
                                  (let ((pa (inbound-reference-path a))
                                        (pb (inbound-reference-path b)))
                                    (or (string< pa pb)
                                        (and (string= pa pb)
                                             (< (inbound-reference-line a)
                                                (inbound-reference-line b)))))))
                  definition definition-document))))))

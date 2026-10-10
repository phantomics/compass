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
  kind path line column field text source
  (name nil))                           ; the alias the reference used, if not the target's own identifier

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
list of INBOUND-REFERENCEs in path and line order. A reference written with any
name of the target counts: its canonical identifier, or an alias the ledger
records for it. Second and third values are what REFERENCE names (a document,
record, or section) and the document holding it, or NIL if it is not defined."
  (multiple-value-bind (id anchor) (split-reference reference)
    (let* ((anchor (and anchor (plusp (length anchor)) anchor))
           (names (corpus-names-of corpus id))
           (canonical (find-if (lambda (name) (or (find-document corpus name)
                                                  (find-record corpus name)))
                               names))
           (document (and canonical (find-document corpus canonical)))
           (record (and canonical (null document) (find-record corpus canonical)))
           (host (or document (and record (record-document record))))
           (target-path (and host (document-path host)))
           (target-fragment (or anchor (and record (record-anchor record))))
           (whole-document-p (and document (null anchor)))
           (written (if anchor
                        (mapcar (lambda (name) (format nil "~a#~a" name anchor)) names)
                        names))
           (counted (make-hash-table :test #'equal))
           (results '()))
      (labels ((add (kind source-document line column field text &optional name)
                 (let ((path (document-path source-document)))
                   (setf (gethash (cons path line) counted) t)
                   (push (make-inbound-reference
                          :kind kind :path path :line line :column column :field field
                          :text (excerpt text) :source (document-id source-document)
                          :name (and name canonical (string/= name canonical) name))
                         results)))
               (counted-p (source-document line)
                 (gethash (cons (document-path source-document) line) counted))
               (name-in (text)
                 "The first name of the target written in TEXT, or NIL."
                 (if anchor
                     (find-if (lambda (w) (search w text)) written)
                     (let ((found (find-identifiers-in-text text)))
                       (find-if (lambda (name) (member name found :test #'string=))
                                names))))
               (link-to-target-p (source-document link)
                 (multiple-value-bind (kind path fragment)
                     (link-destination source-document (link-target link))
                   (let ((fragment (and fragment (plusp (length fragment)) fragment)))
                     (or (member (trim-whitespace (strip-inline-markup (link-text link)))
                                 written :test #'string=)
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
                (let ((name (find (node-string node) names :test #'string=)))
                  (when name
                    (add :relation source (yaml-node-line node) (yaml-node-column node)
                         field (format nil "~a: ~a" field name) name)))))
            ;; Register listings that amend the record
            (unless (some (lambda (name) (document-record source name)) names)
              (dolist (kind (register-kinds))
                (dolist (node (field-value-nodes source (register-kind-field kind)))
                  (let ((name (find (node-string node) names :test #'string=)))
                    (when name
                      (add :register source (yaml-node-line node) (yaml-node-column node)
                           (register-kind-field kind)
                           (format nil "~a: ~a" (register-kind-field kind) name)
                           name)))))))
          ;; Links
          (dolist (link (document-links source))
            (when (link-to-target-p source link)
              (add :link source (location-line link) (location-column link)
                   (link-target link)
                   (format nil "[~a](~a)" (link-text link) (link-target link))
                   (find (trim-whitespace (strip-inline-markup (link-text link))) names
                         :test #'string=))))
          ;; Memo bases
          (unless anchor
            (dolist (memo (document-records source))
              (let ((entry (and (eq (record-kind memo) :memo)
                                (record-field-entry memo "Basis"))))
                (when (and entry (not (counted-p source (field-entry-line entry))))
                  (let ((name (name-in (field-entry-value entry))))
                    (when name
                      (add :basis source (field-entry-line entry) nil (record-id memo)
                           (field-entry-value entry) name)))))))
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
                                        (= line-number (location-line record)))))
                      do (let ((name (name-in line)))
                           (when name
                             (add :mention source line-number
                                  (let ((p (search (if anchor
                                                       (format nil "~a#~a" name anchor)
                                                       name)
                                                   line)))
                                    (and p (1+ p)))
                                  nil line (if anchor nil name))))))))
        (multiple-value-bind (definition definition-document) (resolve corpus reference)
          (values (sort results (lambda (a b)
                                  (let ((pa (inbound-reference-path a))
                                        (pb (inbound-reference-path b)))
                                    (or (string< pa pb)
                                        (and (string= pa pb)
                                             (< (inbound-reference-line a)
                                                (inbound-reference-line b)))))))
                  definition definition-document))))))

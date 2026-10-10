;;;; short.lisp — Find short record references, such as D6, and suggest the identifier each means
;;;;
;;;; Read-if: changing how short references are found or what is suggested for them
;;;; See: COMPASS-DRAFT-toolchain-D26
;;;; Invariant: this file only finds and suggests; nothing here rewrites a document
;;;; Tests: tests/test-allocate.lisp

(in-package #:compass.corpus)

;;; A short reference names a record by its letter and number alone. Which
;;; record it means depends on context a reader supplies and a rewriter cannot
;;; be sure of, and it changes meaning when a record is renumbered. The
;;; toolchain therefore never rewrites one: `ref/short-record` reports each with
;;; a suggestion, an author writes the full identifier, and `compass assign`
;;; refuses while one still points at a record it would renumber.

(defstruct (short-reference)
  line column text                      ; where, and the token as written
  suggestion                            ; the full identifier it probably means, or NIL
  written)                              ; the identifier as the context forms it, before aliases

(defparameter *continuation-scanner*
  (ppcre:create-scanner
   "(?:\\s*,\\s*(?:and\\s+|or\\s+)?|\\s+(?:and|or|to|through)\\s+|\\s*[–—]\\s*|-)([DOM])([1-9][0-9]*)(?![A-Za-z0-9])")
  "A short reference continuing a list after a full identifier, as in \", D10\",
\" to D14\", or \"–D4\".")

(defparameter *bare-record-scanner*
  (ppcre:create-scanner "(?<![A-Za-z0-9#/._@-])([DOM])([1-9][0-9]*)(?![A-Za-z0-9])")
  "A short record reference, such as D6.")

(defparameter *owner-scanner*
  (ppcre:create-scanner "^\\s+(?:of|in|from)\\s+[\\[`(]*")
  "The words that tie short references to the identifier after them, as in
\"O4 and O5 of COMPASS-DRAFT-operator-memory\".")

(defun identifier-family (parsed)
  "The prefix that short references continuing PARSED complete: the provisional
document identifier PARSED is or belongs to, or else its namespace."
  (cond ((not (identifier-provisional-p parsed)) (identifier-namespace parsed))
        ((identifier-register-p parsed) (identifier-host parsed))
        (t (identifier-string parsed))))

(defun after-link (line end)
  "If an identifier ending at END is the text of a link, the position after the
link's destination; otherwise END."
  (if (and (< (1+ end) (length line)) (char= (char line end) #\]) (char= (char line (1+ end)) #\())
      (let ((close (position #\) line :start (+ end 2))))
        (if close (1+ close) end))
      end))

(defun scan-run (line position)
  "The short references continuing a list at POSITION in LINE, as a list of
(START END LETTER SERIAL), and the position after them."
  (let ((run '()))
    (loop
      (multiple-value-bind (ms me rstarts rends)
          (ppcre:scan *continuation-scanner* line :start position)
        (unless (and ms (= ms position)) (return))
        (push (list (aref rstarts 0) (aref rends 1)
                    (subseq line (aref rstarts 0) (aref rends 0))
                    (subseq line (aref rstarts 1) (aref rends 1)))
              run)
        (setf position me)))
    (values (nreverse run) position)))

(defun identifier-at (line position)
  "The identifier that begins exactly at POSITION in LINE, parsed, or NIL."
  (multiple-value-bind (s e) (ppcre:scan *identifier-in-text-scanner* line :start position)
    (and s (= s position) (parse-identifier (subseq line s e)))))

(defun line-short-references (line)
  "The short references in LINE, outside code spans and inline comments, as a
list of (START END LETTER SERIAL OWNER). OWNER is the prefix the context gives
them (from the identifier a list continues, or one introduced by \"of\", \"in\",
or \"from\"), or NIL when only the document they are written in can say."
  (let* ((spans (find-code-spans line))
         (excluded (append spans (find-inline-comments line spans)))
         (covered (copy-list excluded))
         (found '()))
    (flet ((covered-p (s e) (some (lambda (r) (and (< s (cdr r)) (< (car r) e))) covered)))
      (ppcre:do-scans (start end rs re *identifier-in-text-scanner* line)
        (declare (ignore rs re))
        (unless (covered-p start end)
          (let ((parsed (parse-identifier (subseq line start end))))
            (when parsed
              (push (cons start end) covered)
              (dolist (item (scan-run line (after-link line end)))
                (destructuring-bind (s e letter serial) item
                  (unless (covered-p s e)
                    (push (cons s e) covered)
                    (push (list s e letter serial (identifier-family parsed)) found))))))))
      (let ((position 0))
        (loop
          (multiple-value-bind (s e rstarts rends)
              (ppcre:scan *bare-record-scanner* line :start position)
            (unless s (return))
            (if (covered-p s e)
                (setf position e)
                (multiple-value-bind (more after) (scan-run line e)
                  (let ((owner (multiple-value-bind (os oe)
                                   (ppcre:scan *owner-scanner* line :start after)
                                 (and os (= os after)
                                      (let ((parsed (identifier-at line oe)))
                                        (and parsed (identifier-family parsed)))))))
                    (dolist (item (cons (list s e (subseq line (aref rstarts 0) (aref rends 0))
                                              (subseq line (aref rstarts 1) (aref rends 1)))
                                        more))
                      (destructuring-bind (rs re letter serial) item
                        (unless (covered-p rs re)
                          (push (cons rs re) covered)
                          (push (list rs re letter serial owner) found))))
                    (setf position (max after e)))))))))
    (sort found #'< :key #'first)))

(defun resolvable (corpus id)
  "ID if a record of the corpus has it, the canonical identifier if the ledger
records ID as an alias, or NIL."
  (cond ((find-record corpus id) id)
        ((corpus-alias-target corpus id))
        (t nil)))

(defun document-own-prefixes (corpus document)
  "The prefixes a bare short reference in DOCUMENT is most likely completed with,
most likely first: its provisional identifier and its aliases in the ledger;
those of each document it `relates-to`, in order; and last its namespace, for a
record that already has a canonical number."
  (let ((id (document-identifier document))
        (ledger (corpus-ledger corpus)))
    (flet ((names-of (identifier)
             (append (and (identifier-provisional-p identifier)
                          (list (identifier-string identifier)))
                     (ledger-aliases-of ledger (identifier-string identifier)))))
      (when id
        (remove-duplicates
         (append (names-of id)
                 (loop for related in (node-identifiers
                                       (document-field-node document "relates-to"))
                       for target = (let ((d (find-document corpus related)))
                                      (and d (document-identifier d)))
                       when target append (names-of target))
                 (list (identifier-namespace id)))
         :test #'string= :from-end t)))))

(defun paragraph-neighbour (lines kinds index)
  "The line at INDEX if it is text in the same paragraph, else NIL."
  (and (<= 0 index (1- (length lines)))
       (eq (aref kinds index) :text)
       (not (blank-string-p (aref lines index)))
       (aref lines index)))

(defun document-short-references (corpus document)
  "The short record references in DOCUMENT's text and headings, other than in
record headings (which `register/heading-form` reports), as SHORT-REFERENCEs.
A short reference that its context ties to a document (a list continuing a full
identifier, or \"of\", \"in\", or \"from\" followed by one, also across a line
break) is always reported. A bare one is reported only when it matches a record
of this document or of one it relates to; other tokens, such as table labels
like M1, are left alone."
  (let ((kinds (document-line-kinds document))
        (lines (document-lines document))
        (headings (make-hash-table))
        (prefixes (document-own-prefixes corpus document))
        (found '()))
    (dolist (record (document-records document))
      (setf (gethash (location-line record) headings) t))
    (loop for index from 0 below (length lines)
          for line-number = (1+ index)
          for line = (aref lines index)
          when (and (member (aref kinds index) '(:text :heading))
                    (not (gethash line-number headings)))
            do (let* ((text-line-p (eq (aref kinds index) :text))
                      (before (or (and text-line-p (paragraph-neighbour lines kinds (1- index)))
                                  ""))
                      (after (or (and text-line-p (paragraph-neighbour lines kinds (1+ index)))
                                 ""))
                      (offset (if (string= before "") 0 (1+ (length before))))
                      (joined (format nil "~a~:[~; ~]~a~:[~; ~]~a" before (plusp offset) line
                                      (string/= after "") after)))
                 (dolist (item (line-short-references joined))
                   (destructuring-bind (start end letter serial owner) item
                     (when (and (>= start offset) (<= end (+ offset (length line))))
                       (let* ((short (format nil "~a~a" letter serial))
                              (written (and owner (format nil "~a-~a" owner short)))
                              (suggestion
                                (if owner
                                    (or (resolvable corpus written) written)
                                    (loop for prefix in prefixes
                                          for candidate = (format nil "~a-~a" prefix short)
                                          for resolved = (resolvable corpus candidate)
                                          when resolved
                                            do (setf written candidate)
                                            and return resolved))))
                         (when (or owner suggestion)
                           (push (make-short-reference
                                  :line line-number :column (1+ (- start offset))
                                  :text short :suggestion suggestion :written written)
                                 found))))))))
    (nreverse found)))

(defun short-references-to (corpus identifiers)
  "Short references anywhere in the corpus that probably mean one of IDENTIFIERS,
as (DOCUMENT SHORT-REFERENCE)."
  (let ((found '()))
    (dolist (document (corpus-documents corpus))
      (dolist (short (document-short-references corpus document))
        (when (or (member (short-reference-written short) identifiers :test #'equal)
                  (member (short-reference-suggestion short) identifiers :test #'equal))
          (push (list document short) found))))
    (nreverse found)))

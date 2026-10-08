;;;; show.lisp — Print a document, a section, or a record by identifier
;;;;
;;;; Read-if: changing what `compass show` prints
;;;; See: COMPASS-DRAFT-toolchain-D21
;;;; Tests: tests/test-corpus.lisp

(in-package #:compass.corpus)

(defun line-slice (document first last)
  (let ((lines (document-lines document)))
    (join-lines (coerce (subseq lines (max 0 (1- first)) (min (length lines) last))
                        'list))))

(defun show (corpus reference)
  "The source text for REFERENCE: a whole document for \"ID\", one section for
\"ID#anchor\", or one record for a record identifier. Return the text, the
document's path, and the first and last line numbers; or NIL."
  (multiple-value-bind (object document) (resolve corpus reference)
    (when object
      (multiple-value-bind (first last)
          (etypecase object
            (document (values 1 (length (document-lines document))))
            (section (values (location-line object) (section-end-line object)))
            (register-record (values (location-line object) (record-end-line object))))
        ;; Trim trailing blank lines from a section or record.
        (loop while (and (> last first)
                         (blank-string-p (aref (document-lines document) (1- last))))
              do (decf last))
        (values (line-slice document first last) (document-path document) first last)))))

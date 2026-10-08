;;;; report.lisp — Write findings as text or JSON, and compute the exit code
;;;;
;;;; Read-if: changing the format of `compass check` output or its exit codes
;;;; See: COMPASS-DRAFT-toolchain
;;;; Invariant: exit 0 when clean (warnings allowed unless --strict), 1 when there are errors
;;;; Tests: tests/test-cli.lisp

(in-package #:compass.report)

(defun sort-findings (findings)
  (stable-sort (copy-list findings) #'compass.rules::finding<))

(defun summarize (findings &optional corpus)
  "A property list counting FINDINGS by severity, with corpus totals."
  (list :errors (count :error findings :key #'finding-severity)
        :warnings (count :warning findings :key #'finding-severity)
        :documents (if corpus (length (corpus-documents corpus)) 0)
        :skipped (if corpus (length (corpus-skipped corpus)) 0)
        :unverified (if corpus (length (corpus-unverified corpus)) 0)))

(defun exit-code (findings &key strict)
  "0 if FINDINGS has no errors (and, with STRICT, no warnings); otherwise 1."
  (if (or (find :error findings :key #'finding-severity)
          (and strict findings))
      1
      0))

(defun plural (n singular &optional (plural (concatenate 'string singular "s")))
  (format nil "~d ~a" n (if (= n 1) singular plural)))

(defun write-text (findings stream corpus)
  (dolist (f findings)
    (format stream "~a:~a:~@[~a:~] ~(~a~) ~a: ~a~%"
            (or (finding-path f) "-") (or (finding-line f) 1) (finding-column f)
            (finding-severity f) (finding-rule f) (finding-message f)))
  (destructuring-bind (&key errors warnings documents skipped unverified)
      (summarize findings corpus)
    (format stream "~&Checked ~a: ~a, ~a.~%"
            (plural documents "document") (plural errors "error") (plural warnings "warning"))
    (when (plusp skipped)
      (format stream "Skipped ~a without front-matter (--skip-unmarked).~%"
              (plural skipped "file")))
    (when (plusp unverified)
      (format stream "Did not verify ~a into namespaces that are not loaded.~%"
              (plural unverified "reference")))))

(defun object (&rest pairs)
  (let ((table (make-hash-table :test #'equal)))
    (loop for (key value) on pairs by #'cddr
          do (setf (gethash key table) value))
    table))

(defun json-value (x) (or x :null))

(defun write-json (findings stream corpus version)
  (destructuring-bind (&key errors warnings documents skipped unverified)
      (summarize findings corpus)
    (let ((shasht:*write-indent-string* "  ")
          (*print-pretty* t))
      (shasht:write-json
       (object "tool" "compass"
               "version" version
               "root" (if corpus (uiop:native-namestring (corpus-root corpus)) :null)
               "summary" (object "documents" documents "errors" errors
                                 "warnings" warnings "skipped" skipped
                                 "unverified" unverified)
               "findings" (coerce
                           (mapcar (lambda (f)
                                     (object "path" (json-value (finding-path f))
                                             "line" (json-value (finding-line f))
                                             "column" (json-value (finding-column f))
                                             "severity" (string-downcase
                                                         (symbol-name (finding-severity f)))
                                             "rule" (finding-rule f)
                                             "message" (finding-message f)))
                                   findings)
                           'vector)
               "skipped" (coerce (if corpus (corpus-skipped corpus) '()) 'vector)
               "unverified" (coerce
                             (mapcar (lambda (u)
                                       (destructuring-bind (path line reference) u
                                         (object "path" path "line" (json-value line)
                                                 "reference" reference)))
                                     (if corpus (corpus-unverified corpus) '()))
                             'vector))
       stream)
      (terpri stream))))

(defun write-findings (findings stream &key (format :text) corpus (version ""))
  "Write FINDINGS to STREAM as :TEXT or :JSON."
  (ecase format
    (:text (write-text findings stream corpus))
    (:json (write-json findings stream corpus version))))

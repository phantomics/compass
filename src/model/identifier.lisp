;;;; identifier.lisp — Canonical and provisional identifiers for documents and records
;;;;
;;;; Read-if: changing identifier grammar, provisional identifiers, or ID#anchor references
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D2
;;;; Invariant: slugs are lowercase, so the uppercase -D/-O/-M suffix of a provisional record is unambiguous
;;;; Tests: tests/test-identifier.lisp

(in-package #:compass.model)

(defstruct (identifier (:constructor %make-identifier))
  (string "" :type string)
  (namespace "")
  (kind :document :type (member :document :decision :open-question :memo))
  (serial nil)
  (slug nil)
  (provisional-p nil))

(defparameter +namespace-pattern+ "[A-Z][A-Z0-9]*")
(defparameter +slug-pattern+ "[a-z0-9]+(?:-[a-z0-9]+)*")

(defparameter *canonical-document-scanner*
  (ppcre:create-scanner (format nil "^(~a)-([0-9]{4,})$" +namespace-pattern+)))
(defparameter *canonical-record-scanner*
  (ppcre:create-scanner (format nil "^(~a)-([DOM])([1-9][0-9]*)$" +namespace-pattern+)))
(defparameter *provisional-document-scanner*
  (ppcre:create-scanner (format nil "^(~a)-DRAFT-(~a)$" +namespace-pattern+
                                +slug-pattern+)))
(defparameter *provisional-record-scanner*
  (ppcre:create-scanner (format nil "^(~a)-DRAFT-(~a)-([DOM])([1-9][0-9]*)$"
                                +namespace-pattern+ +slug-pattern+)))

(defun letter-kind (letter)
  (register-kind-keyword (find-register-kind (char letter 0))))

(defun parse-identifier (string)
  "Parse STRING as a Compass identifier. Return an IDENTIFIER, or NIL if STRING
is not one."
  (when (stringp string)
    (or (ppcre:register-groups-bind (namespace serial)
            (*canonical-document-scanner* string)
          (%make-identifier :string string :namespace namespace :kind :document
                            :serial (and serial (parse-integer serial))))
        (ppcre:register-groups-bind (namespace letter serial)
            (*canonical-record-scanner* string)
          (%make-identifier :string string :namespace namespace
                            :kind (letter-kind letter)
                            :serial (and serial (parse-integer serial))))
        (ppcre:register-groups-bind (namespace slug letter serial)
            (*provisional-record-scanner* string)
          (%make-identifier :string string :namespace namespace
                            :kind (letter-kind letter) :serial (and serial (parse-integer serial))
                            :slug slug :provisional-p t))
        (ppcre:register-groups-bind (namespace slug)
            (*provisional-document-scanner* string)
          (%make-identifier :string string :namespace namespace :kind :document
                            :slug slug :provisional-p t)))))

(defun identifier-document-p (identifier)
  (eq (identifier-kind identifier) :document))

(defun identifier-register-p (identifier)
  (not (identifier-document-p identifier)))

(defun identifier-host (identifier)
  "For a provisional record, the identifier string of the document it belongs to."
  (and (identifier-provisional-p identifier)
       (identifier-register-p identifier)
       (format nil "~a-DRAFT-~a" (identifier-namespace identifier)
               (identifier-slug identifier))))

(defun format-canonical-identifier (namespace kind serial)
  "The canonical identifier string for SERIAL of KIND in NAMESPACE."
  (if (eq kind :document)
      (format nil "~a-~4,'0d" namespace serial)
      (format nil "~a-~a~d" namespace
              (register-kind-letter (find-register-kind kind)) serial)))

(defun split-reference (string)
  "Split \"ID#anchor\" into the identifier string and the anchor (or NIL)."
  (let ((hash (position #\# string)))
    (if hash
        (values (subseq string 0 hash) (subseq string (1+ hash)))
        (values string nil))))

(defun diagnose-identifier (string)
  "Explain why STRING is not a valid document identifier, or return NIL if it is."
  (let ((id (parse-identifier string)))
    (cond ((null string) "the id is missing")
          ((and id (identifier-document-p id)) nil)
          (id (format nil "~a is a record identifier; a document's id is ~
                           <NAMESPACE>-<NNNN>, or <NAMESPACE>-DRAFT-<slug> while ~
                           it is provisional" string))
          ((ppcre:scan "^[A-Z][A-Z0-9]*-[0-9]{1,3}$" string)
           "the serial is zero-padded to at least four digits, as in COMPASS-0007")
          ((ppcre:scan "^[A-Z][A-Z0-9]*-DRAFT-" string)
           "a provisional slug is lowercase letters and digits, separated by single hyphens")
          ((ppcre:scan "^[A-Za-z][A-Za-z0-9]*-" string)
           (if (string/= (subseq string 0 (position #\- string))
                         (string-upcase (subseq string 0 (position #\- string))))
               "the namespace is uppercase letters and digits"
               "expected <NAMESPACE>-<NNNN> or <NAMESPACE>-DRAFT-<slug>"))
          (t "expected <NAMESPACE>-<NNNN> or <NAMESPACE>-DRAFT-<slug>"))))

(defparameter *identifier-in-text-scanner*
  (ppcre:create-scanner
   (format nil "(?<![A-Za-z0-9-])~a-(?:DRAFT-~a(?:-[DOM][1-9][0-9]*)?|[0-9]{4,}|[DOM][1-9][0-9]*)(?![A-Za-z0-9])"
           +namespace-pattern+ +slug-pattern+)))

(defun find-identifiers-in-text (text)
  "Return the identifier strings that appear in TEXT, in order."
  (let ((found '()))
    (ppcre:do-matches-as-strings (match *identifier-in-text-scanner* text)
      (when (parse-identifier match) (push match found)))
    (nreverse found)))

(defun replace-identifiers-in-text (text function)
  "TEXT with each identifier in it replaced by the string FUNCTION returns for
it; where FUNCTION returns NIL, the identifier is left as written. Identifiers
are matched whole, as FIND-IDENTIFIERS-IN-TEXT finds them."
  (let ((pieces '()) (end 0) (changed nil))
    (ppcre:do-scans (start finish reg-starts reg-ends *identifier-in-text-scanner* text)
      (declare (ignore reg-starts reg-ends))
      (let* ((token (subseq text start finish))
             (replacement (and (parse-identifier token) (funcall function token))))
        (when replacement
          (push (subseq text end start) pieces)
          (push replacement pieces)
          (setf end finish changed t))))
    (if changed
        (progn (push (subseq text end) pieces)
               (apply #'concatenate 'string (nreverse pieces)))
        text)))

;;;; ledger.lisp — The allocation ledger, REGISTRY.sexp: reading, formatting, and appending entries
;;;;
;;;; Read-if: changing the ledger's format, what an entry records, or how it is validated
;;;; See: COMPASS-DRAFT-toolchain-D3, COMPASS-DRAFT-toolchain-D22
;;;; Invariant: each entry is one line; the file is only ever appended to
;;;; Invariant: read with the restricted reader, so reading never runs code or interns symbols
;;;; Concerns: security-boundary, persistent-format
;;;; Tests: tests/test-ledger.lisp

(in-package #:compass.model)

(defparameter +ledger-file-name+ "REGISTRY.sexp")

(defstruct (ledger-entry)
  id                                    ; canonical identifier string
  identifier                            ; its parsed IDENTIFIER
  kind                                  ; :document :decision :open-question :memo
  draft                                 ; the provisional identifier it replaced, or NIL
  path                                  ; documents: the path at allocation
  host                                  ; records: the host's identifier at allocation
  date                                  ; YYYY-MM-DD
  by                                    ; the allocator
  (line nil)                            ; line in the ledger file
  (text nil))                           ; the line as written

(defclass ledger ()
  ((path :initarg :path :reader ledger-path
         :documentation "Path relative to the repository root.")
   (text :initarg :text :initform "" :reader ledger-text)
   (entries :initarg :entries :initform '() :reader ledger-entries)
   (by-id :initform (make-hash-table :test #'equal) :reader ledger-by-id)
   (by-alias :initform (make-hash-table :test #'equal) :reader ledger-by-alias)))

(defmethod initialize-instance :after ((ledger ledger) &key)
  (dolist (entry (ledger-entries ledger))
    (push entry (gethash (ledger-entry-id entry) (ledger-by-id ledger)))
    (when (ledger-entry-draft entry)
      (push entry (gethash (ledger-entry-draft entry) (ledger-by-alias ledger)))))
  (maphash (lambda (k v) (setf (gethash k (ledger-by-id ledger)) (reverse v)))
           (ledger-by-id ledger))
  (maphash (lambda (k v) (setf (gethash k (ledger-by-alias ledger)) (reverse v)))
           (ledger-by-alias ledger)))

(defun ledger-entry-for (ledger id)
  "The first entry allocating ID, or NIL."
  (and ledger (first (gethash id (ledger-by-id ledger)))))

(defun ledger-alias-entry (ledger alias)
  "The first entry whose alias is ALIAS, or NIL."
  (and ledger (first (gethash alias (ledger-by-alias ledger)))))

(defun ledger-aliases-of (ledger id)
  "The provisional identifiers the ledger records for ID."
  (and ledger
       (loop for entry in (gethash id (ledger-by-id ledger))
             when (ledger-entry-draft entry) collect (ledger-entry-draft entry))))

(defun ledger-namespace-entries (ledger namespace &optional kind)
  (and ledger
       (remove-if-not (lambda (entry)
                        (and (string= (identifier-namespace (ledger-entry-identifier entry))
                                      namespace)
                             (or (null kind) (eq kind (ledger-entry-kind entry)))))
                      (ledger-entries ledger))))

;;; Reading

(defparameter *ledger-keys* '(:id :kind :draft :path :host :date :by))
(defparameter *ledger-kinds* '(:document :decision :open-question :memo))

(defun conflict-marker-p (line)
  "True if LINE is a Git merge-conflict marker."
  (or (starts-with-p "<<<<<<< " line) (string= line "<<<<<<<")
      (starts-with-p ">>>>>>> " line) (string= line ">>>>>>>")
      (starts-with-p "||||||| " line) (string= line "|||||||")
      (string= line "=======")))

(defun ledger-ignorable-line-p (line)
  (let ((trimmed (trim-whitespace line)))
    (or (string= trimmed "") (starts-with-p ";" trimmed))))

(defun parse-ledger-line (line line-number)
  "Parse one non-blank, non-comment LINE. Return an entry or NIL, and a list of
problems, each (SEVERITY MESSAGE)."
  (let ((problems '()))
    (flet ((problem (control &rest args)
             (push (list :error (apply #'format nil control args)) problems))
           (warning (control &rest args)
             (push (list :warning (apply #'format nil control args)) problems)))
      (cond
        ((conflict-marker-p line)
         (problem "an unresolved merge-conflict marker; run compass renumber, which ~
                   keeps both sides and renumbers this branch's allocations")
         (values nil (nreverse problems)))
        (t
         (let ((forms (handler-case (read-restricted-sexps line)
                        (sexp-syntax-error (e)
                          (problem "~a" (sexp-syntax-error-message e))
                          (return-from parse-ledger-line
                            (values nil (nreverse problems)))))))
           (cond
             ((/= (length forms) 1)
              (problem "a ledger line holds exactly one entry")
              (values nil (nreverse problems)))
             ((not (and (listp (first forms)) (evenp (length (first forms)))
                        (loop for (k) on (first forms) by #'cddr
                              always (or (keywordp k) (foreign-keyword-p k)))))
              (problem "an entry is a property list, such as (:id \"NS-0001\" :kind ~
                        :document ...)")
              (values nil (nreverse problems)))
             (t
              (let* ((plist (first forms))
                     (id (getf plist :id))
                     (kind (getf plist :kind))
                     (draft (getf plist :draft))
                     (path (getf plist :path))
                     (host (getf plist :host))
                     (date (getf plist :date))
                     (by (getf plist :by))
                     (identifier (and (stringp id) (parse-identifier id)))
                     (draft-identifier (and (stringp draft) (parse-identifier draft))))
                (loop for (k) on plist by #'cddr
                      unless (member k *ledger-keys*)
                        do (warning "unrecognised key :~(~a~)"
                                    (if (keywordp k) (symbol-name k)
                                        (foreign-keyword-name k))))
                (cond ((not (stringp id)) (problem "an entry needs :id, a string"))
                      ((or (null identifier) (identifier-provisional-p identifier))
                       (problem ":id ~s is not a canonical identifier" id)))
                (cond ((not (member kind *ledger-kinds*))
                       (problem ":kind must be one of :document, :decision, ~
                                 :open-question, or :memo"))
                      ((and identifier (not (eq kind (identifier-kind identifier))))
                       (problem ":kind :~(~a~) does not match ~a, a~:[~;n~] ~(~a~) ~
                                 identifier"
                                kind id
                                (eq (identifier-kind identifier) :open-question)
                                (substitute #\Space #\- (symbol-name
                                                         (identifier-kind identifier))))))
                (when draft
                  (cond ((not (stringp draft)) (problem ":draft must be a string"))
                        ((not (and draft-identifier
                                   (identifier-provisional-p draft-identifier)))
                         (problem ":draft ~s is not a provisional identifier" draft))
                        ((and identifier (not (eq (identifier-kind draft-identifier)
                                                  (identifier-kind identifier))))
                         (problem ":draft ~a is not the same kind of identifier as ~a"
                                  draft id))))
                (if (eq kind :document)
                    (progn
                      (unless (and (stringp path) (plusp (length path)))
                        (problem "a document entry needs :path, a string"))
                      (when host (problem "a document entry has no :host")))
                    (when (member kind *ledger-kinds*)
                      (unless (and (stringp host) (parse-identifier host)
                                   (identifier-document-p (parse-identifier host)))
                        (problem "a record entry needs :host, its document's identifier"))
                      (when path (problem "a record entry has no :path; it has :host"))))
                (unless (and (stringp date) (valid-date-string-p date))
                  (problem "an entry needs :date, a YYYY-MM-DD date"))
                (unless (and (stringp by) (plusp (length (trim-whitespace by))))
                  (problem "an entry needs :by, the allocator's name"))
                (values (if (find :error problems :key #'first)
                            nil
                            (make-ledger-entry :id id :identifier identifier :kind kind
                                               :draft draft :path path :host host
                                               :date date :by by :line line-number
                                               :text line))
                        (nreverse problems)))))))))))

(defun parse-ledger-text (text &key path (rule "ledger/valid"))
  "Parse the ledger TEXT. Return its entries (the well-formed ones) and a list of
findings under RULE for the rest."
  (let ((entries '()) (findings '()))
    (loop for line across (split-lines text)
          for number from 1
          unless (ledger-ignorable-line-p line)
            do (multiple-value-bind (entry problems) (parse-ledger-line line number)
                 (when entry (push entry entries))
                 (dolist (problem problems)
                   (push (make-finding :rule rule :severity (first problem) :path path
                                       :line number
                                       :message (format nil "~a" (second problem)))
                         findings))))
    (values (nreverse entries) (nreverse findings))))

(defun make-ledger (path text entries)
  (make-instance 'ledger :path path :text text :entries entries))

(defun read-ledger (pathname &key path)
  "Read the ledger at PATHNAME. Return a LEDGER and a list of findings, or NIL
and NIL if there is no such file."
  (when (uiop:file-exists-p pathname)
    (handler-case
        (let ((text (read-text-file pathname)))
          (multiple-value-bind (entries findings) (parse-ledger-text text :path path)
            (values (make-ledger path text entries) findings)))
      (text-file-error (e)
        (values (make-ledger path "" '())
                (list (make-finding :rule "ledger/valid" :severity :error :path path
                                    :line 1
                                    :message (text-file-error-reason e))))))))

;;; Writing

(defun ledger-string (string)
  (with-output-to-string (out)
    (write-char #\" out)
    (loop for c across string
          do (when (member c '(#\" #\\)) (write-char #\\ out))
             (write-char c out))
    (write-char #\" out)))

(defun format-ledger-entry (entry)
  "ENTRY as one ledger line, without a newline, with its keys in a fixed order."
  (with-output-to-string (out)
    (format out "(:id ~a :kind :~(~a~)" (ledger-string (ledger-entry-id entry))
            (ledger-entry-kind entry))
    (when (ledger-entry-draft entry)
      (format out " :draft ~a" (ledger-string (ledger-entry-draft entry))))
    (when (ledger-entry-path entry)
      (format out " :path ~a" (ledger-string (ledger-entry-path entry))))
    (when (ledger-entry-host entry)
      (format out " :host ~a" (ledger-string (ledger-entry-host entry))))
    (format out " :date ~a :by ~a)" (ledger-string (ledger-entry-date entry))
            (ledger-string (ledger-entry-by entry)))))

(defun ledger-header (namespaces)
  (format nil ";;; Compass allocation ledger for ~{~a~^, ~}. Append-only: one entry per line;~%~
               ;;; never edit, reorder, or delete an entry (Compass §13). Maintained by~%~
               ;;; compass assign, compass renumber, and compass init --ledger.~%"
          namespaces))

(defun ledger-text-with-entries (text entries &key namespaces)
  "TEXT, an existing ledger's text (or NIL for a new ledger), with ENTRIES
appended, each on its own line."
  (with-output-to-string (out)
    (if (and text (plusp (length text)))
        (progn (write-string text out)
               (unless (char= (char text (1- (length text))) #\Newline)
                 (terpri out)))
        (write-string (ledger-header namespaces) out))
    (dolist (entry entries)
      (write-string (format-ledger-entry entry) out)
      (terpri out))))

(defun today ()
  "Today's date, YYYY-MM-DD, in local time."
  (multiple-value-bind (s m h day month year) (decode-universal-time (get-universal-time))
    (declare (ignore s m h))
    (format nil "~4,'0d-~2,'0d-~2,'0d" year month day)))

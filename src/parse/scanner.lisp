;;;; scanner.lisp — Line-oriented scanner for document bodies
;;;;
;;;; Read-if: changing what the body scanner records (headings, records, links, tables, fences)
;;;; See: COMPASS-DRAFT-toolchain-D7, COMPASS-DRAFT-toolchain-D16
;;;; Invariant: nothing inside fenced code or block HTML comments is read as structure
;;;; Tests: tests/test-scanner.lisp

(in-package #:compass.parse)

;;; The scanner does not build a full CommonMark tree; it records the structure
;;; the rules need, each element with its line. A full tree is left to the
;;; Markdown→Lexis importer (S2), which extends this scanner.

(defstruct (body)
  sections records links images tables fences code-spans)

(defparameter *fence-open-scanner*
  (ppcre:create-scanner "^( {0,3})(`{3,}|~{3,})(.*)$"))

(defparameter *heading-scanner*
  (ppcre:create-scanner "^ {0,3}(#{1,6})(?:[ \\t]+(.*?))?[ \\t]*$"))

(defparameter *delimiter-row-scanner*
  (ppcre:create-scanner "^\\s*\\|?\\s*:?-+:?\\s*(?:\\|\\s*:?-+:?\\s*)*\\|?\\s*$"))

(defparameter *field-line-scanner*
  (ppcre:create-scanner
   "^\\*\\*([A-Za-z][A-Za-z]*(?:-[A-Za-z]+)*)(?::\\*\\*|\\*\\*:)(?:[ \\t]+(.*))?$"))

(defparameter *record-heading-scanner*
  (ppcre:create-scanner
   "^([A-Z][A-Z0-9]*-(?:DRAFT-[a-z0-9]+(?:-[a-z0-9]+)*-)?[DOM][1-9][0-9]*)\\s+(—|–|--|-)\\s+(.+)$"))

(defparameter *short-record-heading-scanner*
  (ppcre:create-scanner "^([DOM])([1-9][0-9]*)\\s+(—|–|--|-)\\s+(.+)$"))

(defun heading-text (line)
  "If LINE is an ATX heading, return its level and text."
  (ppcre:register-groups-bind (hashes text) (*heading-scanner* line)
    (let ((text (or text "")))
      ;; Remove an optional closing sequence of #s preceded by space.
      (let ((closing (ppcre:scan "[ \\t]+#+$" text)))
        (when closing (setf text (subseq text 0 closing))))
      (when (every (lambda (c) (char= c #\#)) text) (setf text ""))
      (values (length hashes) (trim-whitespace text)))))

(defun classify-lines (lines start)
  "Classify each line from index START: :blank, :text, :heading, :fence (the
fence lines and their content), or :comment (block HTML comments). Return the
vector of kinds and the list of fences."
  (let ((kinds (make-array (length lines) :initial-element :front-matter))
        (fences '())
        (fence nil)                     ; (char length info start-index)
        (in-comment nil))
    (loop for i from start below (length lines)
          for line = (aref lines i)
          do (cond
               (fence
                (setf (aref kinds i) :fence)
                (destructuring-bind (char length info open) fence
                  (let* ((indent (or (position #\Space line :test #'char/=) (length line)))
                         (rest (string-right-trim '(#\Space #\Tab) (subseq line indent))))
                    (when (and (<= indent 3)
                               (>= (length rest) length)
                               (every (lambda (c) (char= c char)) rest))
                      (push (make-instance 'fence :line (1+ open) :column 1
                                                  :info info :end-line (1+ i)
                                                  :closed-p t)
                            fences)
                      (setf fence nil)))))
               (in-comment
                (setf (aref kinds i) :comment)
                (when (search "-->" line) (setf in-comment nil)))
               ((blank-string-p line) (setf (aref kinds i) :blank))
               ((ppcre:scan *fence-open-scanner* line)
                (ppcre:register-groups-bind (indent marker info)
                    (*fence-open-scanner* line)
                  (declare (ignore indent))
                  (if (and (char= (char marker 0) #\`) (find #\` info))
                      (setf (aref kinds i) :text) ; not a fence: backticks in info
                      (progn
                        (setf (aref kinds i) :fence)
                        (setf fence (list (char marker 0) (length marker)
                                          (trim-whitespace info) i))))))
               ((ppcre:scan "^ {0,3}<!--" line)
                (setf (aref kinds i) :comment)
                (unless (search "-->" line :start2 (+ 4 (search "<!--" line)))
                  (setf in-comment t)))
               ((heading-text line) (setf (aref kinds i) :heading))
               (t (setf (aref kinds i) :text))))
    (when fence
      (destructuring-bind (char length info open) fence
        (declare (ignore char length))
        (push (make-instance 'fence :line (1+ open) :column 1 :info info
                                    :end-line (length lines) :closed-p nil)
              fences)))
    (values kinds (nreverse fences))))

(defun table-row-p (line)
  (char= (char (string-left-trim '(#\Space) line) 0) #\|))

(defun inline-units (lines kinds start)
  "Group lines into units for inline scanning: each heading line and each table
row is a unit; consecutive other text lines form one unit. Return a list of
lists of line indices."
  (let ((units '()) (current '()))
    (flet ((flush () (when current (push (nreverse current) units) (setf current '()))))
      (loop for i from start below (length lines)
            for kind = (aref kinds i)
            do (cond ((eq kind :heading) (flush) (push (list i) units))
                     ((eq kind :text)
                      (if (table-row-p (aref lines i))
                          (progn (flush) (push (list i) units))
                          (push i current)))
                     (t (flush))))
      (flush))
    (nreverse units)))

(defun scan-inline-unit (lines indices)
  "Scan one unit for code spans, links, and images. Return three lists."
  (let* ((texts (mapcar (lambda (i) (aref lines i)) indices))
         (text (string-join texts (string #\Newline)))
         (starts (let ((offset 0))
                   (mapcar (lambda (s) (prog1 offset (incf offset (1+ (length s)))))
                           texts)))
         (spans (find-code-spans text))
         (comments (find-inline-comments text spans))
         (links (find-links text (append spans comments)))
         (code-spans '()) (found-links '()) (images '()))
    (flet ((position-of (offset)
             (loop for (start . more) on starts
                   for index in indices
                   when (or (null more) (< offset (first more)))
                     return (values (1+ index) (1+ (- offset start))))))
      (dolist (span spans)
        (multiple-value-bind (line column) (position-of (car span))
          (push (make-instance 'code-span :line line :column column
                                          :text (code-span-content text span))
                code-spans)))
      (dolist (link links)
        (destructuring-bind (start link-text target image-p) link
          (multiple-value-bind (line column) (position-of start)
            (let ((object (make-instance 'link :line line :column column
                                               :text link-text :target target
                                               :image-p image-p)))
              (if image-p (push object images) (push object found-links)))))))
    (values (nreverse code-spans) (nreverse found-links) (nreverse images))))

(defun build-sections (lines kinds start)
  (let ((sections '()) (occurrences (make-hash-table :test #'equal)))
    (flet ((unique-anchor (base)
             (let ((slug base))
               (when (gethash slug occurrences)
                 (loop do (setf slug (format nil "~a-~d" base
                                             (incf (gethash base occurrences))))
                       while (gethash slug occurrences)))
               (setf (gethash slug occurrences) 0)
               slug)))
      (loop for i from start below (length lines)
            when (eq (aref kinds i) :heading)
              do (multiple-value-bind (level text) (heading-text (aref lines i))
                   (let ((parent (find-if (lambda (s) (< (section-level s) level))
                                          sections)))
                     (push (make-instance 'section :line (1+ i) :column 1 :level level
                                                   :text text
                                                   :anchor (unique-anchor
                                                            (heading-anchor text))
                                                   :parent parent)
                           sections)))))
    (let ((ordered (nreverse sections)))
      (loop for (section . rest) on ordered
            do (setf (section-end-line section)
                     (let ((next (find-if (lambda (s) (<= (section-level s)
                                                         (section-level section)))
                                          rest)))
                       (if next (1- (location-line next)) (length lines)))))
      ordered)))

(defun build-tables (lines kinds start)
  (let ((tables '()) (i start) (n (length lines)))
    (loop while (< i n)
          do (if (and (eq (aref kinds i) :text)
                      (find #\| (aref lines i))
                      (< (1+ i) n)
                      (eq (aref kinds (1+ i)) :text)
                      (find #\| (aref lines (1+ i)))
                      (ppcre:scan *delimiter-row-scanner* (aref lines (1+ i))))
                 (let* ((header (aref lines i))
                        (end (loop for j from (+ i 2) below n
                                   unless (and (eq (aref kinds j) :text)
                                               (find #\| (aref lines j)))
                                     return j
                                   finally (return n)))
                        (cells (let ((row (trim-whitespace header)))
                                 (when (starts-with-p "|" row) (setf row (subseq row 1)))
                                 (when (and (ends-with-p "|" row)
                                            (not (ends-with-p "\\|" row)))
                                   (setf row (subseq row 0 (1- (length row)))))
                                 (mapcar #'trim-whitespace
                                         (ppcre:split "(?<!\\\\)\\|" row)))))
                   (multiple-value-bind (caption caption-line)
                       (let ((j (1- i)))
                         (loop while (and (>= j start) (eq (aref kinds j) :blank))
                               do (decf j))
                         (when (and (>= j start) (eq (aref kinds j) :text))
                           (let ((first j))
                             (loop while (and (> first start)
                                              (eq (aref kinds (1- first)) :text))
                                   do (decf first))
                             (let ((head (trim-whitespace (aref lines first))))
                               (when (starts-with-p "Table:" head)
                                 (values
                                  (trim-whitespace
                                   (subseq (string-join
                                            (loop for k from first to j
                                                  collect (trim-whitespace (aref lines k)))
                                            " ")
                                           6))
                                  (1+ first)))))))
                     (push (make-instance 'table-block :line (1+ i) :column 1
                                                       :caption caption
                                                       :caption-line caption-line
                                                       :header-cells cells
                                                       :end-line end)
                           tables))
                   (setf i end))
                 (incf i)))
    (nreverse tables)))

(defun strip-comments (text)
  (ppcre:regex-replace-all "<!--.*?-->" text ""))

(defun record-fields-in (lines kinds from to)
  "Collect bold-label fields (**Label:** value) from lines FROM to TO (indices)."
  (let ((fields '()) (current nil))
    (loop for i from from to (min to (1- (length lines)))
          for line = (aref lines i)
          do (cond
               ((not (eq (aref kinds i) :text)) (setf current nil))
               ((ppcre:scan *field-line-scanner* line)
                (ppcre:register-groups-bind (label value) (*field-line-scanner* line)
                  (setf current (make-field-entry :label label :value (or value "")
                                                  :line (1+ i)))
                  (push current fields)))
               (current
                (setf (field-entry-value current)
                      (concatenate 'string (field-entry-value current) " "
                                   (trim-whitespace line))))))
    (dolist (field fields)
      (setf (field-entry-value field)
            (trim-whitespace (strip-comments (field-entry-value field)))))
    (nreverse fields)))

(defun build-records (lines kinds sections namespace)
  (let ((records '()))
    (dolist (section sections)
      (let* ((text (strip-inline-markup (section-text section)))
             (level (section-level section))
             (from (location-line section))   ; index of the line after the heading
             (to (1- (section-end-line section))))
        (when (<= 2 level 4)
          (multiple-value-bind (id separator title short-p)
              (multiple-value-bind (match groups)
                  (ppcre:scan-to-strings *record-heading-scanner* text)
                (if match
                    (values (aref groups 0) (aref groups 1) (aref groups 2) nil)
                    (multiple-value-bind (match groups)
                        (ppcre:scan-to-strings *short-record-heading-scanner* text)
                      (when (and match namespace)
                        (values (format nil "~a-~a~a" namespace (aref groups 0)
                                        (aref groups 1))
                                (aref groups 2) (aref groups 3) t)))))
            (let ((identifier (and id (parse-identifier id))))
              (when (and identifier (identifier-register-p identifier))
                (push (make-instance 'register-record
                                     :line (location-line section) :column 1
                                     :id id :identifier identifier
                                     :title (trim-whitespace title)
                                     :level level :short-form-p short-p
                                     :separator separator
                                     :fields (record-fields-in lines kinds from to)
                                     :end-line (section-end-line section))
                      records)))))))
    (nreverse records)))

(defun scan-body (lines &key (start 0) namespace)
  "Scan the body of a document. LINES is the vector of all its lines; the body
begins at index START. NAMESPACE, the document's namespace, is used to read
short record headings. Return a BODY."
  (multiple-value-bind (kinds fences) (classify-lines lines start)
    (let ((sections (build-sections lines kinds start))
          (code-spans '()) (links '()) (images '()))
      (dolist (unit (inline-units lines kinds start))
        (multiple-value-bind (spans unit-links unit-images) (scan-inline-unit lines unit)
          (setf code-spans (revappend spans code-spans)
                links (revappend unit-links links)
                images (revappend unit-images images))))
      (make-body :sections sections
                 :records (build-records lines kinds sections namespace)
                 :links (nreverse links)
                 :images (nreverse images)
                 :tables (build-tables lines kinds start)
                 :fences fences
                 :code-spans (nreverse code-spans)))))

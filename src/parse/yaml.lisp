;;;; yaml.lisp — Strict YAML-subset parser for front-matter
;;;;
;;;; Read-if: changing what front-matter syntax is accepted, or how YAML errors are reported
;;;; See: COMPASS-DRAFT-toolchain-D18
;;;; Invariant: every scalar is returned as a string or null; no YAML 1.1 type conversion happens
;;;; Invariant: anything outside the subset is an error with a line and column, never a guess
;;;; Concerns: security-boundary
;;;; Tests: tests/test-yaml.lisp

(in-package #:compass.parse)

;;; The subset, from COMPASS-DRAFT-toolchain-D18:
;;;   - a top-level block mapping, with nested block mappings;
;;;   - block sequences of scalars or of mappings, and one-line flow sequences
;;;     of scalars;
;;;   - plain, single-quoted, and double-quoted scalars, each on one line;
;;;   - # comments, and the null forms ~, null, and an empty value.
;;; Everything else is rejected: tab indentation, duplicate keys, anchors,
;;; aliases, tags, block scalars, flow mappings, explicit ? keys, multi-line
;;; scalars, multiple documents, and ": " inside a plain scalar.

(define-condition front-matter-syntax-error (error)
  ((line :initarg :line :reader front-matter-syntax-error-line)
   (column :initarg :column :reader front-matter-syntax-error-column)
   (message :initarg :message :reader front-matter-syntax-error-message))
  (:report (lambda (c s)
             (format s "~a (line ~a, column ~a)" (front-matter-syntax-error-message c)
                     (front-matter-syntax-error-line c)
                     (front-matter-syntax-error-column c)))))

(defun yaml-fail (line column format-control &rest args)
  (error 'front-matter-syntax-error
         :line line :column column
         :message (apply #'format nil format-control args)))

(defstruct (yline)
  (number 0)
  (indent 0)
  (content ""))

(defun yline-column (yline) (1+ (yline-indent yline)))

(defun prepare-lines (text start-line)
  "Split TEXT into YLINEs, dropping blank and comment-only lines."
  (let ((result '()))
    (loop for raw across (split-lines text)
          for number from start-line
          do (let* ((first (position-if-not (lambda (c) (char= c #\Space)) raw)))
               (cond
                 ((null first))
                 ((char= (char raw first) #\Tab)
                  (if (blank-string-p raw)
                      nil
                      (yaml-fail number (1+ first)
                                 "a tab is used for indentation; indent with spaces")))
                 (t
                  (let ((content (string-right-trim '(#\Space #\Tab) (subseq raw first))))
                    (cond
                      ((char= (char content 0) #\#))
                      ((and (zerop first) (member content '("---" "...") :test #'string=))
                       (yaml-fail number 1 "document markers (--- and ...) are not ~
                                            supported inside front-matter"))
                      ((and (zerop first) (char= (char content 0) #\%))
                       (yaml-fail number 1 "YAML directives (%) are not supported"))
                      (t (push (make-yline :number number :indent first :content content)
                               result))))))))
    (coerce (nreverse result) 'simple-vector)))

(defun sequence-item-p (content)
  (or (string= content "-") (starts-with-p "- " content)))

(defparameter *key-line-scanner*
  (ppcre:create-scanner "^[A-Za-z_][A-Za-z0-9_-]*:(?:[ \\t]|$)"))

(defun key-line-p (content)
  (and (ppcre:scan *key-line-scanner* content) t))

(defun comment-or-blank-p (text)
  (let ((trimmed (string-left-trim '(#\Space #\Tab) text)))
    (or (string= trimmed "") (char= (char trimmed 0) #\#))))

(defun null-scalar (line column)
  (make-yaml-scalar :line line :column column :value nil :style :null))

;;; Scalars on one line

(defun parse-double-quoted (text start line column-base)
  "Parse a double-quoted scalar beginning at index START of TEXT (at the quote).
Return the string and the index after the closing quote."
  (let ((out (make-string-output-stream))
        (i (1+ start))
        (n (length text)))
    (flet ((fail (message &rest args)
             (apply #'yaml-fail line (+ column-base i) message args))
           (hex (count)
             (let ((digits (and (<= (+ i 1 count) n)
                                (subseq text (1+ i) (+ i 1 count)))))
               (unless (and digits (every (lambda (c) (digit-char-p c 16)) digits))
                 (yaml-fail line (+ column-base i) "malformed \\x, \\u, or \\U escape"))
               (incf i count)
               (code-char (parse-integer digits :radix 16)))))
      (loop
        (when (>= i n)
          (yaml-fail line (+ column-base start)
                     "a quoted value must close on the same line"))
        (let ((c (char text i)))
          (cond
            ((char= c #\") (return (values (get-output-stream-string out) (1+ i))))
            ((char= c #\\)
             (when (>= (1+ i) n)
               (fail "a quoted value must close on the same line"))
             (let ((e (char text (1+ i))))
               (incf i)
               (write-char
                (case e
                  (#\0 (code-char 0)) (#\a (code-char 7)) (#\b (code-char 8))
                  ((#\t #\Tab) #\Tab) (#\n #\Newline) (#\v (code-char 11))
                  (#\f (code-char 12)) (#\r #\Return) (#\e (code-char 27))
                  (#\Space #\Space) (#\" #\") (#\/ #\/) (#\\ #\\)
                  (#\N (code-char #x85)) (#\_ (code-char #xA0))
                  (#\L (code-char #x2028)) (#\P (code-char #x2029))
                  (#\x (hex 2)) (#\u (hex 4)) (#\U (hex 8))
                  (t (fail "unsupported escape \\~a in a quoted value" e)))
                out)))
            (t (write-char c out))))
        (incf i)))))

(defun parse-single-quoted (text start line column-base)
  "Parse a single-quoted scalar beginning at index START of TEXT."
  (let ((out (make-string-output-stream))
        (i (1+ start))
        (n (length text)))
    (loop
      (when (>= i n)
        (yaml-fail line (+ column-base start)
                   "a quoted value must close on the same line"))
      (let ((c (char text i)))
        (cond ((and (char= c #\') (< (1+ i) n) (char= (char text (1+ i)) #\'))
               (write-char #\' out)
               (incf i))
              ((char= c #\') (return (values (get-output-stream-string out) (1+ i))))
              (t (write-char c out))))
      (incf i))))

(defun check-trailing (text index line column-base)
  "After a quoted scalar or flow list ends at INDEX, allow only space and a comment."
  (let ((rest (subseq text index)))
    (unless (or (string= rest "")
                (and (member (char rest 0) '(#\Space #\Tab))
                     (comment-or-blank-p rest)))
      (yaml-fail line (+ column-base index)
                 "unexpected text after the value; only a # comment may follow"))))

(defun check-plain (value line column)
  (let ((colon (or (search ": " value)
                   (and (ends-with-p ":" value) (1- (length value))))))
    (when colon
      (yaml-fail line (+ column colon)
                 "\": \" cannot appear in an unquoted value; put the value in quotes"))))

(defun plain-scalar (text line column)
  "Parse TEXT as a plain scalar, removing a trailing comment."
  (let* ((comment (loop for i from 1 below (length text)
                        when (and (char= (char text i) #\#)
                                  (member (char text (1- i)) '(#\Space #\Tab)))
                          return i))
         (value (string-right-trim '(#\Space #\Tab) (subseq text 0 comment))))
    (check-plain value line column)
    (if (member value '("~" "null" "Null" "NULL") :test #'string=)
        (null-scalar line column)
        (make-yaml-scalar :line line :column column :value value :style :plain))))

(defun parse-flow-sequence (text line column)
  "Parse a one-line flow sequence of scalars, TEXT beginning with [."
  (let ((items '()) (i 1) (n (length text)))
    (flet ((skip () (loop while (and (< i n) (member (char text i) '(#\Space #\Tab)))
                          do (incf i)))
           (fail (message) (yaml-fail line (+ column i) message)))
      (loop
        (skip)
        (when (>= i n) (yaml-fail line column "a flow list must close on the same line"))
        (when (char= (char text i) #\])
          (incf i)
          (return))
        (let ((c (char text i)) (item-column (+ column i)))
          (cond
            ((char= c #\")
             (multiple-value-bind (s end) (parse-double-quoted text i line column)
               (push (make-yaml-scalar :line line :column item-column :value s
                                       :style :double)
                     items)
               (setf i end)))
            ((char= c #\')
             (multiple-value-bind (s end) (parse-single-quoted text i line column)
               (push (make-yaml-scalar :line line :column item-column :value s
                                       :style :single)
                     items)
               (setf i end)))
            ((member c '(#\[ #\{))
             (fail "nested flow collections are not supported"))
            ((char= c #\,) (fail "empty item in a flow list"))
            (t
             (let* ((end (or (position-if (lambda (d) (member d '(#\, #\])))
                                          text :start i)
                             n))
                    (raw (string-right-trim '(#\Space #\Tab) (subseq text i end))))
               (when (find #\# raw)
                 (fail "a comment cannot appear inside a flow list"))
               (when (find-if (lambda (d) (member d '(#\{ #\[ #\})))
                              raw)
                 (fail "nested flow collections are not supported"))
               (check-plain raw line item-column)
               (push (if (member raw '("~" "null" "Null" "NULL") :test #'string=)
                         (null-scalar line item-column)
                         (make-yaml-scalar :line line :column item-column :value raw
                                           :style :plain))
                     items)
               (setf i end)))))
        (skip)
        (when (>= i n) (yaml-fail line column "a flow list must close on the same line"))
        (case (char text i)
          (#\, (incf i))
          (#\] (incf i) (return))
          (t (fail "expected , or ] in a flow list")))))
    (check-trailing text i line column)
    (make-yaml-sequence :line line :column column :items (nreverse items))))

(defun parse-inline-value (text line column)
  "Parse the value TEXT that follows a key or a sequence dash on one line.
TEXT has no leading space; COLUMN is the column of its first character."
  (let ((c (char text 0)))
    (case c
      (#\" (multiple-value-bind (s end) (parse-double-quoted text 0 line column)
             (check-trailing text end line column)
             (make-yaml-scalar :line line :column column :value s :style :double)))
      (#\' (multiple-value-bind (s end) (parse-single-quoted text 0 line column)
             (check-trailing text end line column)
             (make-yaml-scalar :line line :column column :value s :style :single)))
      (#\[ (parse-flow-sequence text line column))
      (#\{ (yaml-fail line column "flow mappings ({ }) are not supported; ~
                                   write the mapping in block form"))
      ((#\| #\>) (yaml-fail line column "block scalars (| and >) are not supported; ~
                                         keep the value on one line"))
      (#\& (yaml-fail line column "anchors (&) are not supported"))
      (#\* (yaml-fail line column "aliases (*) are not supported"))
      (#\! (yaml-fail line column "tags (!) are not supported"))
      ((#\@ #\`) (yaml-fail line column "a value cannot begin with ~a; quote it" c))
      (#\% (yaml-fail line column "a value cannot begin with %; quote it"))
      (t
       (cond ((sequence-item-p text)
              (yaml-fail line column "a list cannot begin on the same line as its key; ~
                                      put each item on its own line"))
             ((or (string= text "?") (starts-with-p "? " text))
              (yaml-fail line column "explicit keys (?) are not supported"))
             ((or (string= text ":") (starts-with-p ": " text))
              (yaml-fail line column "unexpected \":\""))
             (t (plain-scalar text line column)))))))

;;; Blocks

(defun parse-block (lines i)
  (let ((line (aref lines i)))
    (if (sequence-item-p (yline-content line))
        (parse-sequence lines i (yline-indent line))
        (parse-mapping lines i (yline-indent line)))))

(defun split-key (line)
  "Split a mapping line into its key and the text after the colon. Return the
key, the rest (left-trimmed), and the column where the rest begins."
  (let* ((content (yline-content line))
         (column (yline-column line))
         (n (length content))
         (end (and (plusp n)
                   (or (alpha-char-p (char content 0)) (char= (char content 0) #\_))
                   (or (position-if-not (lambda (c) (or (alphanumericp c)
                                                        (member c '(#\_ #\-))))
                                        content)
                       n))))
    (cond
      ((null end)
       (yaml-fail (yline-number line) column
                  (case (char content 0)
                    ((#\" #\') "quoted keys are not supported")
                    (#\? "explicit keys (?) are not supported")
                    ((#\{ #\[) "flow collections are not supported")
                    (t "expected a line of the form \"key: value\""))))
      ((or (>= end n) (char/= (char content end) #\:))
       (yaml-fail (yline-number line) (+ column end)
                  (if (and (< end n) (member (char content end) '(#\Space #\Tab))
                           (let ((next (position-if-not
                                        (lambda (c) (member c '(#\Space #\Tab)))
                                        content :start end)))
                             (and next (char= (char content next) #\:))))
                      "no space is allowed between a key and its colon"
                      "expected \":\" after the key ~s")
                  (subseq content 0 end)))
      ((and (< (1+ end) n) (not (member (char content (1+ end)) '(#\Space #\Tab))))
       (yaml-fail (yline-number line) (+ column end 1)
                  "a space is required after \"~a:\"" (subseq content 0 end)))
      (t
       (let ((rest-start (or (position-if-not (lambda (c) (member c '(#\Space #\Tab)))
                                              content :start (1+ end))
                             n)))
         (values (subseq content 0 end)
                 (subseq content rest-start)
                 (+ column rest-start)))))))

(defun parse-mapping (lines i indent)
  "Parse a block mapping whose keys are at INDENT, starting at line index I.
Return the mapping and the index of the first line after it."
  (let ((entries '())
        (n (length lines))
        (first (aref lines i)))
    (loop while (< i n)
          do (let ((line (aref lines i)))
               (cond
                 ((< (yline-indent line) indent) (return))
                 ((> (yline-indent line) indent)
                  (yaml-fail (yline-number line) (yline-column line)
                             "unexpected indentation; a value must fit on one line ~
                              (multi-line values are not supported)"))
                 ((sequence-item-p (yline-content line))
                  (yaml-fail (yline-number line) (yline-column line)
                             "a list item where a key was expected"))
                 (t
                  (multiple-value-bind (key rest rest-column) (split-key line)
                    (when (find key entries :key #'yaml-entry-key :test #'string=)
                      (yaml-fail (yline-number line) (yline-column line)
                                 "duplicate key ~s" key))
                    (let ((value nil))
                      (if (comment-or-blank-p rest)
                          (let ((next (and (< (1+ i) n) (aref lines (1+ i)))))
                            (cond
                              ((and next (> (yline-indent next) indent))
                               (multiple-value-setq (value i) (parse-block lines (1+ i))))
                              ((and next (= (yline-indent next) indent)
                                    (sequence-item-p (yline-content next)))
                               (multiple-value-setq (value i)
                                 (parse-sequence lines (1+ i) indent)))
                              (t (setf value (null-scalar (yline-number line) rest-column))
                                 (incf i))))
                          (progn
                            (setf value (parse-inline-value rest (yline-number line)
                                                            rest-column))
                            (incf i)))
                      (push (make-yaml-entry :key key :line (yline-number line)
                                             :column (yline-column line) :value value)
                            entries)))))))
    (values (make-yaml-mapping :line (yline-number first) :column (yline-column first)
                               :entries (nreverse entries))
            i)))

(defun parse-sequence (lines i indent)
  "Parse a block sequence whose dashes are at INDENT, starting at line index I."
  (let ((items '())
        (n (length lines))
        (first (aref lines i)))
    (loop while (< i n)
          do (let ((line (aref lines i)))
               (cond
                 ((< (yline-indent line) indent) (return))
                 ((> (yline-indent line) indent)
                  (yaml-fail (yline-number line) (yline-column line)
                             "unexpected indentation; a value must fit on one line ~
                              (multi-line values are not supported)"))
                 ((not (sequence-item-p (yline-content line))) (return))
                 (t
                  (let* ((content (yline-content line))
                         (after (string-left-trim '(#\Space) (subseq content 1)))
                         (offset (- (length content) (length after)))
                         (item-indent (+ indent offset)))
                    (cond
                      ((comment-or-blank-p after)
                       (let ((next (and (< (1+ i) n) (aref lines (1+ i)))))
                         (if (and next (> (yline-indent next) indent))
                             (multiple-value-bind (value next-i)
                                 (parse-block lines (1+ i))
                               (push value items)
                               (setf i next-i))
                             (progn
                               (push (null-scalar (yline-number line)
                                                  (+ (yline-column line) 1))
                                     items)
                               (incf i)))))
                      ((or (sequence-item-p after) (key-line-p after))
                       ;; A nested sequence or a mapping that begins on the dash's
                       ;; line: reread this line as if it began at the item.
                       (setf (yline-indent line) item-indent
                             (yline-content line) after)
                       (multiple-value-bind (value next-i) (parse-block lines i)
                         (push value items)
                         (setf i next-i)))
                      (t
                       (push (parse-inline-value after (yline-number line)
                                                 (1+ item-indent))
                             items)
                       (incf i))))))))
    (values (make-yaml-sequence :line (yline-number first) :column (yline-column first)
                                :items (nreverse items))
            i)))

(defun parse-yaml-subset (text &key (start-line 1))
  "Parse TEXT, the lines of a front-matter block, as the strict YAML subset.
START-LINE is the line number of TEXT's first line in its file. Return a
YAML-MAPPING; signal FRONT-MATTER-SYNTAX-ERROR outside the subset."
  (let ((lines (prepare-lines text start-line)))
    (if (zerop (length lines))
        (make-yaml-mapping :line start-line :column 1 :entries '())
        (let ((first (aref lines 0)))
          (unless (zerop (yline-indent first))
            (yaml-fail (yline-number first) (yline-column first)
                       "front-matter keys begin in the first column"))
          (when (sequence-item-p (yline-content first))
            (yaml-fail (yline-number first) 1
                       "front-matter must be a mapping of keys to values, not a list"))
          (multiple-value-bind (mapping next) (parse-mapping lines 0 0)
            (when (< next (length lines))
              (let ((line (aref lines next)))
                (yaml-fail (yline-number line) (yline-column line)
                           "unexpected indentation")))
            mapping)))))

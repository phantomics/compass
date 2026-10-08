;;;; sexp.lisp — Restricted s-expression reader for the manifest and ledger
;;;;
;;;; Read-if: changing what the manifest or ledger may contain, or how they are parsed
;;;; See: COMPASS-DRAFT-toolchain-D3, COMPASS-DRAFT-toolchain-D4
;;;; Invariant: never calls the Lisp reader, never evaluates, never interns a symbol
;;;; Concerns: security-boundary
;;;; Tests: tests/test-sexp.lisp

(in-package #:compass.model)

;;; The manifest and ledger are data written by people and by pull requests,
;;; including ones from forks. They are read by this small tokenizer rather
;;; than by CL:READ: it accepts strings, integers, keywords, and lists, and
;;; nothing else. A keyword is returned as an existing keyword symbol only if
;;; one is already interned; any other keyword is returned as a FOREIGN-KEYWORD
;;; holding its name, so reading never creates symbols.

(define-condition sexp-syntax-error (error)
  ((message :initarg :message :reader sexp-syntax-error-message)
   (line :initarg :line :reader sexp-syntax-error-line)
   (column :initarg :column :reader sexp-syntax-error-column))
  (:report (lambda (c s)
             (format s "~a at line ~a, column ~a" (sexp-syntax-error-message c)
                     (sexp-syntax-error-line c) (sexp-syntax-error-column c)))))

(defstruct (foreign-keyword (:constructor make-foreign-keyword (name)))
  (name "" :type string))

(defparameter *sexp-max-depth* 32)
(defparameter *sexp-max-integer-digits* 18)
(defparameter *sexp-max-string-length* 65536)

(defun read-restricted-sexps (string)
  "Read every form in STRING with the restricted grammar. Return the list of
forms, and a hash table mapping each list form to its starting line.
Signal SEXP-SYNTAX-ERROR on anything outside the grammar."
  (let ((pos 0) (line 1) (column 1)
        (length (length string))
        (lines (make-hash-table :test #'eq)))
    (labels ((peek () (and (< pos length) (char string pos)))
             (advance ()
               (let ((c (char string pos)))
                 (incf pos)
                 (if (char= c #\Newline)
                     (setf line (1+ line) column 1)
                     (incf column))
                 c))
             (fail (format-control &rest args)
               (error 'sexp-syntax-error
                      :message (apply #'format nil format-control args)
                      :line line :column column))
             (skip-space ()
               (loop for c = (peek)
                     while c
                     do (cond ((member c '(#\Space #\Tab #\Newline #\Return #\Page))
                               (advance))
                              ((char= c #\;)
                               (loop for d = (peek)
                                     while (and d (char/= d #\Newline))
                                     do (advance)))
                              (t (return)))))
             (token-char-p (c)
               (and c (not (member c '(#\Space #\Tab #\Newline #\Return #\Page
                                       #\( #\) #\" #\;)))))
             (read-token ()
               (with-output-to-string (out)
                 (loop while (token-char-p (peek))
                       do (write-char (advance) out))))
             (read-string-literal ()
               (advance)
               (let ((out (make-string-output-stream)) (count 0))
                 (loop
                   (let ((c (peek)))
                     (cond ((null c) (fail "unterminated string"))
                           ((char= c #\") (advance) (return))
                           ((char= c #\\)
                            (advance)
                            (let ((e (peek)))
                              (unless (member e '(#\" #\\))
                                (fail "unsupported escape in string; only \\\" and \\\\ are allowed"))
                              (write-char (advance) out)))
                           (t (write-char (advance) out))))
                   (when (> (incf count) *sexp-max-string-length*)
                     (fail "string too long")))
                 (get-output-stream-string out)))
             (read-atom ()
               (let ((token (read-token)))
                 (cond
                   ((zerop (length token))
                    (fail "unexpected character ~s" (peek)))
                   ((ppcre:scan "^[+-]?[0-9]+$" token)
                    (when (> (length (string-left-trim "+-" token))
                             *sexp-max-integer-digits*)
                      (fail "integer too large"))
                    (parse-integer token))
                   ((char= (char token 0) #\:)
                    (let ((name (string-upcase (subseq token 1))))
                      (unless (and (plusp (length name))
                                   (every (lambda (c) (or (alphanumericp c) (char= c #\-)))
                                          name))
                        (fail "malformed keyword ~s" token))
                      (multiple-value-bind (symbol status) (find-symbol name "KEYWORD")
                        (if status symbol (make-foreign-keyword name)))))
                   ((find (char token 0) "#'`,|")
                    (fail "reader syntax ~s is not allowed" token))
                   ((string= token ".")
                    (fail "dotted pairs are not allowed"))
                   (t (fail "only strings, integers, keywords, and lists are allowed; found ~s"
                            token)))))
             (read-form (depth)
               (skip-space)
               (let ((c (peek)))
                 (cond
                   ((null c) (fail "unexpected end of input"))
                   ((char= c #\()
                    (when (> depth *sexp-max-depth*) (fail "nesting too deep"))
                    (let ((start-line line))
                      (advance)
                      (let ((items '()))
                        (loop
                          (skip-space)
                          (let ((d (peek)))
                            (cond ((null d) (fail "unterminated list"))
                                  ((char= d #\)) (advance) (return))
                                  (t (push (read-form (1+ depth)) items)))))
                        (let ((list (nreverse items)))
                          (when list (setf (gethash list lines) start-line))
                          list))))
                   ((char= c #\)) (fail "unexpected )"))
                   ((char= c #\") (read-string-literal))
                   (t (read-atom))))))
      (let ((forms '()))
        (loop
          (skip-space)
          (unless (peek) (return))
          (push (read-form 0) forms))
        (values (nreverse forms) lines)))))

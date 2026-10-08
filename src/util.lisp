;;;; util.lisp — String, path, and file helpers shared by every layer
;;;;
;;;; Read-if: reading or writing files, computing repository-relative paths, or adding a helper
;;;; Invariant: files are read and written as UTF-8 with LF line endings; CRLF is accepted on input
;;;; Invariant: paths are handled through uiop, never by native namestring concatenation

(in-package #:compass.util)

;;; Files

(define-condition text-file-error (error)
  ((pathname :initarg :pathname :reader text-file-error-pathname)
   (reason :initarg :reason :reader text-file-error-reason))
  (:report (lambda (c s)
             (format s "cannot read ~a as UTF-8 text: ~a"
                     (text-file-error-pathname c) (text-file-error-reason c)))))

(defun read-text-file (pathname)
  "Return the contents of PATHNAME decoded as UTF-8, without a leading byte-order
mark. Signal TEXT-FILE-ERROR if the file cannot be read or decoded."
  (let ((text (handler-case
                  (alexandria:read-file-into-string pathname :external-format :utf-8)
                (error (e)
                  (error 'text-file-error :pathname pathname
                                          :reason (princ-to-string e))))))
    (if (and (plusp (length text))
             (char= (char text 0) (code-char #xFEFF)))
        (subseq text 1)
        text)))

(defun write-text-file (pathname string)
  "Write STRING to PATHNAME as UTF-8, replacing any existing file."
  (ensure-directories-exist pathname)
  (with-open-file (out pathname :direction :output :if-exists :supersede
                                :if-does-not-exist :create :external-format :utf-8)
    (write-string string out))
  pathname)

;;; Strings

(defparameter +whitespace+ '(#\Space #\Tab))

(defun trim-whitespace (string)
  (string-trim '(#\Space #\Tab #\Return #\Newline) string))

(defun blank-string-p (string)
  (every (lambda (c) (member c '(#\Space #\Tab #\Return #\Newline))) string))

(defun starts-with-p (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun ends-with-p (suffix string)
  (and (<= (length suffix) (length string))
       (string= suffix string :start2 (- (length string) (length suffix)))))

(defun split-lines (text)
  "Split TEXT into a vector of lines. A trailing carriage return is removed from
each line, and a final newline does not produce an empty last line."
  (let ((lines (make-array 0 :adjustable t :fill-pointer t))
        (start 0)
        (length (length text)))
    (loop
      (let* ((end (or (position #\Newline text :start start) length))
             (line (subseq text start end)))
        (when (and (plusp (length line))
                   (char= (char line (1- (length line))) #\Return))
          (setf line (subseq line 0 (1- (length line)))))
        (when (or (< end length) (< start length))
          (vector-push-extend line lines))
        (when (>= end length) (return))
        (setf start (1+ end))))
    (coerce lines 'simple-vector)))

(defun string-join (strings separator)
  (with-output-to-string (out)
    (loop for (string . rest) on strings
          do (write-string string out)
             (when rest (write-string separator out)))))

(defun join-lines (lines)
  "Join LINES with newlines, ending with a newline when LINES is non-empty."
  (with-output-to-string (out)
    (map nil (lambda (line) (write-string line out) (terpri out)) lines)))

(defun edit-distance (a b)
  "The Levenshtein distance between strings A and B."
  (let* ((n (length b))
         (previous (make-array (1+ n)))
         (current (make-array (1+ n))))
    (dotimes (j (1+ n)) (setf (aref previous j) j))
    (dotimes (i (length a))
      (setf (aref current 0) (1+ i))
      (dotimes (j n)
        (setf (aref current (1+ j))
              (min (1+ (aref previous (1+ j)))
                   (1+ (aref current j))
                   (+ (aref previous j)
                      (if (char-equal (char a i) (char b j)) 0 1)))))
      (rotatef previous current))
    (aref previous n)))

(defun closest-match (word candidates &key (max-distance 2))
  "The candidate closest to WORD, ignoring case and treating _ as -, if within
MAX-DISTANCE edits; otherwise NIL."
  (let ((normal (substitute #\- #\_ word))
        (best nil)
        (best-distance (1+ max-distance)))
    (dolist (candidate candidates best)
      (let ((d (edit-distance normal candidate)))
        (when (< d best-distance)
          (setf best candidate best-distance d))))))

(defun valid-date-string-p (string)
  "True if STRING is a YYYY-MM-DD date naming a real calendar day."
  (and (stringp string)
       (= (length string) 10)
       (char= (char string 4) #\-)
       (char= (char string 7) #\-)
       (every #'digit-char-p (remove #\- string))
       (let ((year (parse-integer string :start 0 :end 4))
             (month (parse-integer string :start 5 :end 7))
             (day (parse-integer string :start 8 :end 10)))
         (and (<= 1 month 12)
              (<= 1 day
                  (case month
                    ((4 6 9 11) 30)
                    (2 (if (and (zerop (mod year 4))
                                (or (plusp (mod year 100)) (zerop (mod year 400))))
                           29 28))
                    (t 31)))))))

;;; Paths
;;;
;;; Inside the toolchain a file is named by its path relative to the repository
;;; root, written with forward slashes ("doc/Plan.Toolchain.md").

(defun relative-path-string (pathname root)
  "PATHNAME as a forward-slash path relative to the directory ROOT, or its
native namestring if it is not beneath ROOT."
  (let ((relative (uiop:enough-pathname pathname root)))
    (if (eq (first (pathname-directory relative)) :absolute)
        (uiop:native-namestring pathname)
        (format nil "~{~a/~}~@[~a~]"
                (mapcar (lambda (part) (if (member part '(:up :back)) ".." part))
                        (rest (pathname-directory relative)))
                (let ((name (file-namestring relative)))
                  (and (plusp (length name)) name))))))

(defun normalize-relative-path (base target)
  "Resolve the forward-slash path TARGET against the directory path BASE (both
relative to the repository root; BASE is \"\" or ends in /). Return the
normalized path, and a second value that is true if the path leaves the root."
  (let ((parts (if (starts-with-p "/" target)
                   '()
                   (reverse (butlast (uiop:split-string base :separator "/")))))
        (escapes nil)
        (pieces (uiop:split-string target :separator "/")))
    (dolist (piece pieces)
      (cond ((or (string= piece "") (string= piece ".")))
            ((string= piece "..")
             (if parts (pop parts) (setf escapes t)))
            (t (push piece parts))))
    (let ((path (string-join (reverse parts) "/")))
      (when (and (ends-with-p "/" target) (plusp (length path)))
        (setf path (concatenate 'string path "/")))
      (values path escapes))))

(defun percent-decode (string)
  "Decode %XX escapes in STRING as UTF-8. Malformed escapes are left as written."
  (if (not (find #\% string))
      string
      (let ((octets (make-array 0 :element-type '(unsigned-byte 8)
                                  :adjustable t :fill-pointer t)))
        (loop with i = 0
              while (< i (length string))
              do (let ((c (char string i)))
                   (if (and (char= c #\%)
                            (<= (+ i 3) (length string))
                            (digit-char-p (char string (+ i 1)) 16)
                            (digit-char-p (char string (+ i 2)) 16))
                       (progn
                         (vector-push-extend
                          (parse-integer string :start (+ i 1) :end (+ i 3) :radix 16)
                          octets)
                         (incf i 3))
                       (progn
                         (loop for byte across (babel-free-encode (string c))
                               do (vector-push-extend byte octets))
                         (incf i)))))
        (or (ignore-errors (babel-free-decode octets)) string))))

(defun babel-free-encode (string)
  (let ((octets (make-array 0 :element-type '(unsigned-byte 8)
                              :adjustable t :fill-pointer t)))
    (loop for c across string
          for code = (char-code c)
          do (cond ((< code #x80) (vector-push-extend code octets))
                   ((< code #x800)
                    (vector-push-extend (logior #xC0 (ash code -6)) octets)
                    (vector-push-extend (logior #x80 (logand code #x3F)) octets))
                   ((< code #x10000)
                    (vector-push-extend (logior #xE0 (ash code -12)) octets)
                    (vector-push-extend (logior #x80 (logand (ash code -6) #x3F)) octets)
                    (vector-push-extend (logior #x80 (logand code #x3F)) octets))
                   (t
                    (vector-push-extend (logior #xF0 (ash code -18)) octets)
                    (vector-push-extend (logior #x80 (logand (ash code -12) #x3F)) octets)
                    (vector-push-extend (logior #x80 (logand (ash code -6) #x3F)) octets)
                    (vector-push-extend (logior #x80 (logand code #x3F)) octets))))
    octets))

(defun babel-free-decode (octets)
  "Decode the UTF-8 OCTETS into a string; signal an error if malformed."
  (with-output-to-string (out)
    (let ((i 0) (n (length octets)))
      (flet ((continuation ()
               (when (>= i n) (error "truncated UTF-8 sequence"))
               (let ((b (aref octets i)))
                 (unless (= (logand b #xC0) #x80) (error "malformed UTF-8"))
                 (incf i)
                 (logand b #x3F))))
        (loop while (< i n)
              do (let ((b (aref octets i)))
                   (incf i)
                   (write-char
                    (code-char
                     (cond ((< b #x80) b)
                           ((= (logand b #xE0) #xC0)
                            (logior (ash (logand b #x1F) 6) (continuation)))
                           ((= (logand b #xF0) #xE0)
                            (let* ((b1 (continuation)) (b2 (continuation)))
                              (logior (ash (logand b #x0F) 12) (ash b1 6) b2)))
                           ((= (logand b #xF8) #xF0)
                            (let* ((b1 (continuation)) (b2 (continuation))
                                   (b3 (continuation)))
                              (logior (ash (logand b #x07) 18) (ash b1 12)
                                      (ash b2 6) b3)))
                           (t (error "malformed UTF-8"))))
                    out)))))))

(defun root-file (root relative)
  "The pathname of the forward-slash path RELATIVE beneath the directory ROOT.
Characters such as * are taken literally, never as wildcards."
  (uiop:merge-pathnames* (uiop:parse-unix-namestring relative) root))

(defun file-kind (root relative)
  "Return :FILE, :DIRECTORY, or NIL for the forward-slash path RELATIVE beneath ROOT."
  (let ((trimmed (string-right-trim "/" relative)))
    (cond ((string= trimmed "") :directory)
          ((uiop:directory-exists-p (root-file root (concatenate 'string trimmed "/")))
           :directory)
          ((uiop:file-exists-p (root-file root trimmed)) :file)
          (t nil))))

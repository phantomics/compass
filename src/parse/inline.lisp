;;;; inline.lisp — Inline Markdown: code spans, comments, links, heading anchors, code references
;;;;
;;;; Read-if: changing link detection, heading anchors, or the code-reference grammar
;;;; See: COMPASS-DRAFT-toolchain-D21, COMPASS-0001
;;;; Invariant: heading anchors follow GitHub's rule, including -1, -2 suffixes for repeats
;;;; Tests: tests/test-scanner.lisp

(in-package #:compass.parse)

;;; Regions are (START . END) index pairs, END exclusive.

(defun region-at (position regions)
  (find-if (lambda (r) (and (<= (car r) position) (< position (cdr r)))) regions))

(defun backtick-run (text start)
  (let ((end (or (position #\` text :start start :test #'char/=) (length text))))
    (- end start)))

(defun find-code-spans (text)
  "Return the code spans in TEXT as a list of (START . END) regions, including
their backticks, following CommonMark's matching rule."
  (let ((spans '()) (i 0) (n (length text)))
    (loop while (< i n)
          do (let ((c (char text i)))
               (cond
                 ((and (char= c #\\) (< (1+ i) n)) (incf i 2))
                 ((char= c #\`)
                  (let* ((run (backtick-run text i))
                         (close (loop with j = (+ i run)
                                      while (< j n)
                                      do (let ((p (position #\` text :start j)))
                                           (unless p (return nil))
                                           (let ((r (backtick-run text p)))
                                             (when (= r run) (return p))
                                             (setf j (+ p r)))))))
                    (if close
                        (progn (push (cons i (+ close run)) spans)
                               (setf i (+ close run)))
                        (incf i run))))
                 (t (incf i)))))
    (nreverse spans)))

(defun code-span-content (text region)
  "The content of the code span REGION of TEXT, as CommonMark normalizes it."
  (let* ((run (backtick-run text (car region)))
         (raw (substitute #\Space #\Newline
                          (subseq text (+ (car region) run) (- (cdr region) run)))))
    (if (and (>= (length raw) 2)
             (char= (char raw 0) #\Space)
             (char= (char raw (1- (length raw))) #\Space)
             (not (every (lambda (c) (char= c #\Space)) raw)))
        (subseq raw 1 (1- (length raw)))
        raw)))

(defun find-inline-comments (text excluded)
  "Return the regions of HTML comments in TEXT outside the EXCLUDED regions."
  (let ((comments '()) (i 0))
    (loop
      (let ((open (search "<!--" text :start2 i)))
        (unless open (return))
        (let ((region (region-at open excluded)))
          (if region
              (setf i (cdr region))
              (let ((close (search "-->" text :start2 (+ open 4))))
                (unless close (return))
                (push (cons open (+ close 3)) comments)
                (setf i (+ close 3)))))))
    (nreverse comments)))

(defun matching-bracket (text open excluded)
  "The index of the ] matching the [ at OPEN, skipping EXCLUDED regions."
  (let ((depth 0) (i open) (n (length text)))
    (loop while (< i n)
          do (let ((region (region-at i excluded)))
               (if region
                   (setf i (cdr region))
                   (let ((c (char text i)))
                     (cond ((char= c #\\) (incf i 2))
                           ((char= c #\[) (incf depth) (incf i))
                           ((char= c #\])
                            (decf depth)
                            (when (zerop depth) (return-from matching-bracket i))
                            (incf i))
                           (t (incf i)))))))
    nil))

(defun parse-link-destination (text start)
  "Parse a link destination and optional title after the ( at START - 1.
Return the destination and the index after the closing ), or NIL."
  (let ((i start) (n (length text)))
    (flet ((skip-space ()
             (loop while (and (< i n) (member (char text i) '(#\Space #\Tab #\Newline)))
                   do (incf i))))
      (skip-space)
      (let ((destination
              (cond
                ((>= i n) (return-from parse-link-destination nil))
                ((char= (char text i) #\<)
                 (let ((close (position #\> text :start i)))
                   (unless (and close (not (find #\Newline text :start i :end close)))
                     (return-from parse-link-destination nil))
                   (prog1 (subseq text (1+ i) close) (setf i (1+ close)))))
                (t
                 (let ((depth 0) (begin i))
                   (loop while (< i n)
                         do (let ((c (char text i)))
                              (cond ((char= c #\\) (incf i 2))
                                    ((member c '(#\Space #\Tab #\Newline)) (return))
                                    ((char= c #\() (incf depth) (incf i))
                                    ((char= c #\))
                                     (if (zerop depth) (return) (progn (decf depth) (incf i))))
                                    (t (incf i)))))
                   (subseq text begin (min i n)))))))
        (skip-space)
        (when (and (< i n) (member (char text i) '(#\" #\' #\()))
          (let* ((closer (case (char text i) (#\" #\") (#\' #\') (#\( #\))))
                 (close (position closer text :start (1+ i))))
            (unless close (return-from parse-link-destination nil))
            (setf i (1+ close))
            (skip-space)))
        (if (and (< i n) (char= (char text i) #\)))
            (values destination (1+ i))
            nil)))))

(defun find-links (text excluded)
  "Return inline links and images in TEXT outside EXCLUDED regions, as a list of
(START TEXT TARGET IMAGE-P), where START is the index of [ (or ! for an image)."
  (let ((links '()) (i 0) (n (length text)))
    (loop while (< i n)
          do (let ((region (region-at i excluded)))
               (if region
                   (setf i (cdr region))
                   (let ((c (char text i)))
                     (cond
                       ((char= c #\\) (incf i 2))
                       ((char= c #\[)
                        (let ((close (matching-bracket text i excluded))
                              (image-p (and (plusp i) (char= (char text (1- i)) #\!)
                                            (not (and (> i 1)
                                                      (char= (char text (- i 2)) #\\))))))
                          (when (and close (< (1+ close) n)
                                     (char= (char text (1+ close)) #\())
                            (multiple-value-bind (target end)
                                (parse-link-destination text (+ close 2))
                              (declare (ignore end))
                              (when target
                                (push (list (if image-p (1- i) i)
                                            (subseq text (1+ i) close)
                                            target image-p)
                                      links))))
                          (incf i)))
                       (t (incf i)))))))
    (nreverse links)))

;;; Markup stripping and heading anchors

(defun strip-inline-markup (text)
  "Reduce inline Markdown TEXT to its rendered text: code spans keep their
content, links and images keep their text, emphasis asterisks, HTML tags, and
backslash escapes are removed."
  (let* ((spans (find-code-spans text))
         (comments (find-inline-comments text spans))
         (excluded (append spans comments))
         (links (find-links text excluded))
         (out (make-string-output-stream))
         (i 0) (n (length text)))
    (loop while (< i n)
          do (let ((span (find i spans :key #'car))
                   (comment (find i comments :key #'car))
                   (link (find i links :key #'first)))
               (cond
                 (span (write-string (code-span-content text span) out)
                       (setf i (cdr span)))
                 (comment (setf i (cdr comment)))
                 (link
                  (write-string (strip-inline-markup (second link)) out)
                  (let* ((open (if (fourth link) (1+ i) i))
                         (close (matching-bracket text open excluded)))
                    (multiple-value-bind (target end)
                        (parse-link-destination text (+ close 2))
                      (declare (ignore target))
                      (setf i end))))
                 (t
                  (let ((c (char text i)))
                    (cond
                      ((and (char= c #\\) (< (1+ i) n)
                            (find (char text (1+ i)) "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"))
                       (write-char (char text (1+ i)) out)
                       (incf i 2))
                      ((char= c #\*) (incf i))
                      ((and (char= c #\<) (< (1+ i) n)
                            (or (alpha-char-p (char text (1+ i)))
                                (char= (char text (1+ i)) #\/))
                            (position #\> text :start i))
                       (setf i (1+ (position #\> text :start i))))
                      (t (write-char c out) (incf i))))))))
    (get-output-stream-string out)))

(defun slug-char-p (c)
  (or (alphanumericp c)
      (char= c #\-) (char= c #\Space) (char= c #\_)
      #+sbcl (member (sb-unicode:general-category c) '(:mn :mc :me :pc))))

(defun slugify (text)
  "GitHub's slug for already-rendered heading TEXT: lowercase, keep letters,
digits, marks, connector punctuation, hyphens, and spaces, then turn each space
into a hyphen."
  (substitute #\- #\Space
              (remove-if-not #'slug-char-p
                             (string-downcase (trim-whitespace text)))))

(defun heading-anchor (heading-text)
  "The anchor of a heading with inline Markdown HEADING-TEXT, before any
suffix for repeated anchors."
  (slugify (strip-inline-markup heading-text)))

;;; Code references (§9)

(defstruct (code-reference)
  namespace path symbol line-start line-end revision)

(defparameter *code-reference-scanner*
  (ppcre:create-scanner
   "^(?:([A-Z][A-Z0-9]*):)?([^\\s:@#]+)(?::([^\\s@]+)|#L([0-9]+)(?:-L([0-9]+))?)?@([0-9a-fA-F]{7,40}|[A-Za-z0-9][A-Za-z0-9._+/-]*)$"))

(defun parse-code-reference (string)
  "Parse STRING (the content of a code span) as a commit-pinned code reference,
`[NS:]path[:symbol | #Lstart[-Lend]]@revision`. Return a CODE-REFERENCE or NIL."
  (ppcre:register-groups-bind (namespace path symbol start end revision)
      (*code-reference-scanner* string)
    (make-code-reference :namespace namespace :path path :symbol symbol
                         :line-start (and start (parse-integer start))
                         :line-end (and end (parse-integer end))
                         :revision revision)))

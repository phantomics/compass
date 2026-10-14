;;;; expand-short-records.lisp — Write short record references, such as D6, as the full identifiers compass check suggests
;;;;
;;;; Read-if: expanding short record references before compass assign, or promoting this script to a command
;;;; See: COMPASS-D30
;;;; Status: experimental
;;;; Invariant: writes only when given one file and an explicit selection (--count or --only), and only the entries selected
;;;; Invariant: writes nothing to a file unless every chosen finding still matches the file's text
;;;;
;;;; A standalone script, not part of the compass system. Run it from inside a
;;;; corpus:
;;;;
;;;;   sbcl --non-interactive --load src/expand-short-records.lisp \
;;;;        --end-toplevel-options PATH [--count N [--offset K] [--skip LIST] | --only LIST]
;;;;        [--dry-run] [--json REPORT] [--compass PROGRAM]
;;;;
;;;; Without --count or --only it only lists, numbered in file order, the short
;;;; references `compass check` reports (rule ref/short-record) under PATH, a
;;;; file or a directory (`.` for the whole corpus), with the identifier each
;;;; probably means. Given a FILE, it rewrites the entries selected by number:
;;;;
;;;;   --count N        the first N entries
;;;;   --offset K       with --count, pass over the first K and start at #K+1
;;;;   --skip LIST      with --count, pass over these entries; still N rewrites
;;;;   --only LIST      exactly these entries, and nothing else may select
;;;;
;;;; LIST is listing numbers separated by commas, with inclusive ranges, such as
;;;; 1,4,7-9. Numbers always mean the listing's, whatever --offset is. With
;;;; --dry-run it shows the rewrites without writing. The toolchain itself never
;;;; rewrites a short reference (COMPASS-D30), because the suggestion is a guess
;;;; from context; choosing entries by number keeps a person deciding which
;;;; guesses to accept, after reading the list.
;;;;
;;;; The report comes from running `compass check --format json --rule
;;;; ref/short-record` in the current directory, or from a saved report given
;;;; with --json (`-` reads standard input). A saved report goes stale once a
;;;; file it covers is edited; a finding whose text no longer matches stops the
;;;; rewrite of that file before anything is written.
;;;;
;;;; From a REPL, after loading: (expand-short-records-main '("doc/X.md" "--count" "5"))
;;;; returns the exit status instead of quitting.

(in-package #:cl-user)

(require :asdf)

(unless (find-package "QL")
  (let ((setup (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
    (unless (probe-file setup)
      (error "expand-short-records: Quicklisp not found at ~a" setup))
    (load setup)))

(uiop:symbol-call :ql :quickload "shasht" :silent t)

(defparameter *expand-script-directory*
  (uiop:pathname-directory-pathname (or *load-truename* *default-pathname-defaults*))
  "The directory holding this script, from which the repository's bin/compass is found.")

(define-condition expand-failure (simple-error) ()
  (:documentation "A usage error or a refusal, reported on standard error with exit status 2."))

(defun expand-fail (control &rest arguments)
  (error 'expand-failure :format-control control :format-arguments arguments))

;;; Findings

(defstruct (short-finding)
  path                                  ; as the report gives it, relative to its root
  file                                  ; the absolute pathname
  line column                           ; 1-based, in characters
  token                                 ; the short reference as written, such as "D6"
  suggestion)                           ; the full identifier compass suggests, or NIL

(defun parse-short-message (message)
  "The short reference a ref/short-record MESSAGE reports, and the identifier it
suggests, or NIL as the second value when it suggests none."
  (let ((space (position #\Space message))
        (probably (search "probably " message :from-end t)))
    (values (subseq message 0 space)
            (and probably
                 (let ((suggestion (string-trim " ." (subseq message (+ probably 9)))))
                   (and (plusp (length suggestion)) suggestion))))))

(defun default-compass ()
  "This repository's bin/compass if it exists, else compass on the PATH."
  (let ((local (merge-pathnames "bin/compass"
                                (uiop:pathname-parent-directory-pathname
                                 *expand-script-directory*))))
    (if (probe-file local) (namestring local) "compass")))

(defun run-compass-check (program)
  "The JSON report of PROGRAM's ref/short-record findings for the corpus around
the current directory."
  (multiple-value-bind (output error-output status)
      (uiop:run-program (list program "check" "--format" "json" "--rule" "ref/short-record")
                        :output :string :error-output :string :ignore-error-status t)
    ;; 0 is clean and 1 is errors found; either way the report is complete.
    (unless (member status '(0 1))
      (expand-fail "~a check exited ~d: ~a" program status
                   (string-trim '(#\Space #\Newline) error-output)))
    output))

(defun report-findings (json)
  "The ref/short-record findings of the JSON report, as SHORT-FINDINGs sorted by
path, line, and column."
  (let* ((report (handler-case (shasht:read-json json)
                   (error (e) (expand-fail "the report is not valid JSON: ~a" e))))
         (root (and (hash-table-p report) (gethash "root" report)))
         (findings (and (hash-table-p report) (gethash "findings" report))))
    (unless (and (stringp root) (vectorp findings))
      (expand-fail "the report has no root or findings; is it from compass check --format json?"))
    (let ((root (uiop:ensure-directory-pathname root))
          (found '()))
      (loop for finding across findings
            when (equal (gethash "rule" finding) "ref/short-record")
              do (multiple-value-bind (token suggestion)
                     (parse-short-message (gethash "message" finding))
                   (let ((path (gethash "path" finding)))
                     (push (make-short-finding
                            :path path
                            :file (merge-pathnames (uiop:parse-unix-namestring path) root)
                            :line (gethash "line" finding)
                            :column (gethash "column" finding)
                            :token token :suggestion suggestion)
                           found))))
      (sort found (lambda (a b)
                    (let ((pa (short-finding-path a)) (pb (short-finding-path b)))
                      (cond ((string< pa pb) t)
                            ((string> pa pb) nil)
                            ((/= (short-finding-line a) (short-finding-line b))
                             (< (short-finding-line a) (short-finding-line b)))
                            (t (< (short-finding-column a) (short-finding-column b))))))))))

(defun same-file-p (a b)
  (let ((ta (probe-file a)) (tb (probe-file b)))
    (and ta tb (equal (namestring ta) (namestring tb)))))

;;; Files

(defun read-lines (file)
  "FILE's lines, as a vector of strings. A CR before each LF stays in its line,
so writing the lines back joined by LF keeps CRLF files as they were."
  (coerce (uiop:split-string (uiop:read-file-string file :external-format :utf-8)
                             :separator '(#\Newline))
          'vector))

(defun write-lines (file lines)
  (with-open-file (out file :direction :output :if-exists :supersede
                            :external-format :utf-8)
    (loop for i from 0 below (length lines)
          do (when (plusp i) (write-char #\Newline out))
             (write-string (aref lines i) out))))

(defun finding-bounds (finding)
  "The start and end of FINDING's token in its line, as 0-based positions."
  (let ((start (1- (short-finding-column finding))))
    (values start (+ start (length (short-finding-token finding))))))

(defun finding-matches-p (lines finding)
  "True if FINDING's token still stands, as a whole word, where the report says."
  (multiple-value-bind (start end) (finding-bounds finding)
    (let ((index (1- (short-finding-line finding))))
      (and (< -1 index (length lines))
           (let ((text (aref lines index)))
             (and (<= 0 start) (<= end (length text))
                  (string= (short-finding-token finding) text :start2 start :end2 end)
                  (or (zerop start) (not (alphanumericp (char text (1- start)))))
                  (or (= end (length text)) (not (alphanumericp (char text end))))))))))

(defun excerpt (text start end &optional (width 40))
  "TEXT around START..END, with that span in brackets and at most WIDTH
characters of context on each side."
  (let ((from (max 0 (- start width)))
        (to (min (length text) (+ end width))))
    (format nil "~:[~;…~]~a[~a]~a~:[~;…~]"
            (plusp from) (subseq text from start) (subseq text start end)
            (subseq text end to) (< to (length text)))))

;;; Listing

(defun list-findings (findings)
  "Print FINDINGS grouped by file: the ones with a suggestion numbered in the
order --count takes them, then any without one."
  (let ((groups '()))
    (dolist (finding findings)
      (let ((group (assoc (short-finding-path finding) groups :test #'string=)))
        (if group
            (push finding (cdr group))
            (push (list (short-finding-path finding) finding) groups))))
    (when (null groups)
      (format t "No short record references found.~%"))
    (dolist (group (nreverse groups))
      (let* ((path (car group))
             (members (reverse (cdr group)))
             (lines (and (probe-file (short-finding-file (first members)))
                         (read-lines (short-finding-file (first members)))))
             (suggested (remove nil members :key #'short-finding-suggestion))
             (unsuggested (remove-if #'short-finding-suggestion members)))
        (format t "~&~a: ~d short reference~:p~@[, ~d without a suggestion~]~%"
                path (length members) (and unsuggested (length unsuggested)))
        (flet ((show (label finding)
                 (format t "  ~4@a  ~5d:~3a ~4a -> ~a~%" label
                         (short-finding-line finding) (short-finding-column finding)
                         (short-finding-token finding)
                         (or (short-finding-suggestion finding) "(no suggestion; edit by hand)"))
                 (cond ((null lines) (format t "              (file not found)~%"))
                       ((finding-matches-p lines finding)
                        (multiple-value-bind (start end) (finding-bounds finding)
                          (format t "              ~a~%"
                                  (excerpt (aref lines (1- (short-finding-line finding)))
                                           start end))))
                       (t (format t "              (stale: the text no longer matches; rerun compass check)~%")))))
          (loop for finding in suggested for n from 1 do (show n finding))
          (dolist (finding unsuggested) (show "-" finding)))))
    (when groups
      (format t "~&~%Expand entries in a file with FILE --count N [--offset K] [--skip LIST], ~
                 or FILE --only LIST, where LIST is numbers above such as 1,4,7-9. ~
                 Add --dry-run to preview.~%"))))

;;; Selecting

;;; Every number below is an entry's number in the file's listing: its place
;;; among the findings that have a suggestion, counting from 1, whatever
;;; --offset is. A person reads the numbers off the listing and types them back.

(defun select-findings (suggested &key count (offset 0) skip only)
  "The entries of SUGGESTED, a file's findings that have a suggestion in listing
order, chosen by the options, as (NUMBER . FINDING) pairs in listing order.
With ONLY, a sorted list of listing numbers, exactly those entries. Otherwise
COUNT entries, starting after the first OFFSET and passing over the listing
numbers in SKIP. Refuses a number that would select nothing or have no effect."
  (let ((available (length suggested)))
    (flet ((entry (n) (cons n (nth (1- n) suggested))))
      (if only
          (let ((missing (remove-if (lambda (n) (<= n available)) only)))
            (when missing
              (expand-fail "--only names ~{#~d~^, ~}, but the file lists only ~d entr~:@p with a suggestion"
                           missing available))
            (mapcar #'entry only))
          (let ((early (remove-if (lambda (n) (> n offset)) skip))
                (remaining (- available offset
                              (count-if (lambda (n) (< offset n (1+ available))) skip))))
            (when early
              (expand-fail "--skip names ~{#~d~^, ~}, at or before --offset ~d, where nothing is taken anyway"
                           early offset))
            (when (< remaining count)
              ;; One line: the repository's tests allow a continued line only
              ;; in the controls of operators they know, which this is not.
              (expand-fail "the file lists ~d entr~:@p with a suggestion; after --offset ~d~@[ and ~d skipped~], ~d remain, fewer than --count ~d"
                           available offset
                           (let ((n (- available offset remaining))) (and (plusp n) n))
                           (max remaining 0) count))
            (let ((taken '()) (n offset))
              (loop while (< (length taken) count)
                    do (incf n)
                       (unless (member n skip) (push (entry n) taken)))
              (let ((late (remove-if (lambda (s) (<= s n)) skip)))
                (when late
                  (expand-fail "--skip names ~{#~d~^, ~}, past #~d, the last entry --count ~d takes"
                               late n count)))
              (nreverse taken)))))))

;;; Expanding

(defun expand-findings (file findings chosen &key dry-run)
  "Rewrite CHOSEN, (NUMBER . FINDING) pairs from SELECT-FINDINGS, all in FILE, as
their suggested identifiers; FINDINGS are all of FILE's findings, for the
summary. With DRY-RUN, only print what would change. Refuses, writing nothing,
if any of the chosen findings no longer matches."
  (let* ((available (count-if #'short-finding-suggestion findings))
         (numbers (mapcar #'car chosen))
         (count (length chosen)))
    (let* ((chosen (mapcar #'cdr chosen))
           (lines (read-lines file))
           (stale (remove-if (lambda (f) (finding-matches-p lines f)) chosen)))
      (when stale
        (expand-fail "~d of the chosen findings no longer match ~a (first at ~d:~d, ~a); ~a"
                     (length stale) (uiop:native-namestring file)
                     (short-finding-line (first stale)) (short-finding-column (first stale))
                     (short-finding-token (first stale))
                     "rerun compass check, or omit --json to run it now. Nothing was written."))
      ;; Right to left within a line, so each column still points at its token.
      (dolist (finding (sort (copy-list chosen)
                             (lambda (a b)
                               (if (= (short-finding-line a) (short-finding-line b))
                                   (> (short-finding-column a) (short-finding-column b))
                                   (< (short-finding-line a) (short-finding-line b))))))
        (multiple-value-bind (start end) (finding-bounds finding)
          (let* ((index (1- (short-finding-line finding)))
                 (text (aref lines index)))
            (setf (aref lines index)
                  (concatenate 'string (subseq text 0 start)
                               (short-finding-suggestion finding) (subseq text end))))))
      ;; Each entry under its listing number, so the report matches the listing.
      (loop for finding in chosen for n in numbers
            do (format t "  ~4d  ~5d:~3a ~4a -> ~a~%" n
                       (short-finding-line finding) (short-finding-column finding)
                       (short-finding-token finding) (short-finding-suggestion finding)))
      (if dry-run
          (format t "~&Would expand ~d of ~d in ~a; nothing written.~%"
                  count available (uiop:native-namestring file))
          (progn
            (write-lines file lines)
            (format t "~&Expanded ~d of ~d in ~a; ~d remain~@[, plus ~d without a suggestion~]. ~
                       Run compass check to confirm, and review with git diff.~%"
                    count available (uiop:native-namestring file) (- available count)
                    (let ((n (- (length findings) available))) (and (plusp n) n)))
            (when (< count available)
              (format t "The remaining entries are now numbered afresh; list the file again ~
                         before choosing more.~%")))))))

;;; Command line

(defparameter *expand-usage*
  "Usage: expand-short-records PATH [--count N [--offset K] [--skip LIST] | --only LIST] [--dry-run] [--json REPORT|-] [--compass PROGRAM]
LIST is listing numbers separated by commas, with inclusive ranges: 1,4,7-9")

(defun parse-natural (string option &key (minimum 1))
  "STRING, the value given to OPTION, as an integer of at least MINIMUM."
  (let ((n (and string (every #'digit-char-p string) (plusp (length string))
                (parse-integer string))))
    (unless (and n (>= n minimum))
      (expand-fail "~a needs a~:[ positive~; non-negative~] integer, not ~s"
                   option (zerop minimum) string))
    n))

(defun parse-number-list (string option)
  "STRING, the value given to OPTION, such as \"1,4,7-9\", as a sorted list of
distinct positive integers. Refuses an empty item, a reversed range, a zero,
and a number given twice."
  (unless (and string (plusp (length string)))
    (expand-fail "~a needs a list of listing numbers, such as 1,4,7-9" option))
  (let ((numbers '()))
    (dolist (item (uiop:split-string string :separator ","))
      (when (zerop (length item))
        (expand-fail "~a ~a has an empty item" option string))
      (let* ((dash (position #\- item))
             (low (parse-natural (if dash (subseq item 0 dash) item) option))
             (high (if dash (parse-natural (subseq item (1+ dash)) option) low)))
        (when (< high low)
          (expand-fail "~a ~a has the reversed range ~a" option string item))
        (loop for n from low to high
              do (when (member n numbers)
                   (expand-fail "~a ~a names #~d twice" option string n))
                 (push n numbers))))
    (sort numbers #'<)))

(defun expand-short-records-main (arguments)
  "Run the script on ARGUMENTS, a list of strings as on the command line, and
return the exit status: 0 on success, 2 on a usage error or refusal."
  (handler-case
      (let (file count offset skip only dry-run json program (given-options '()))
        (flet ((value (option)
                 ;; The next argument, unless it is missing or another option.
                 (let ((next (first arguments)))
                   (when (or (null next) (uiop:string-prefix-p "--" next))
                     (expand-fail "~a needs a value" option))
                   (pop arguments))))
          (loop while arguments
                do (let ((argument (pop arguments)))
                     (when (member argument '("--count" "--offset" "--skip" "--only")
                                   :test #'string=)
                       (when (member argument given-options :test #'string=)
                         (expand-fail "~a is given twice; give it once" argument))
                       (push argument given-options))
                     (cond ((string= argument "--count")
                            (setf count (parse-natural (value argument) argument)))
                           ((string= argument "--offset")
                            (setf offset (parse-natural (value argument) argument :minimum 0)))
                           ((string= argument "--skip")
                            (setf skip (parse-number-list (value argument) argument)))
                           ((string= argument "--only")
                            (setf only (parse-number-list (value argument) argument)))
                           ((string= argument "--dry-run") (setf dry-run t))
                           ((string= argument "--json") (setf json (value argument)))
                           ((string= argument "--compass") (setf program (value argument)))
                           ((member argument '("-h" "--help") :test #'string=)
                            (format t "~a~%" *expand-usage*)
                            (return-from expand-short-records-main 0))
                           ((and (> (length argument) 1) (char= (char argument 0) #\-))
                            (expand-fail "unknown option ~a~%~a" argument *expand-usage*))
                           (file (expand-fail "give one path at a time~%~a" *expand-usage*))
                           (t (setf file argument))))))
        (when (and only (or count offset skip))
          (expand-fail "--only picks entries by itself; give it without --count, --offset, or --skip"))
        (when (and (or offset skip) (null count))
          (expand-fail "~:[--skip~;--offset~] works with --count, which says how many to rewrite"
                       offset))
        (let ((selecting (or count only)))
          (when (and selecting (null file))
            (expand-fail "~:[--only~;--count~] needs a FILE: expansion works on one file at a time"
                         count))
          (when (and dry-run (null selecting))
            (expand-fail "--dry-run previews a --count or --only; without one, nothing is written anyway")))
        (let* ((given (and file (merge-pathnames file (uiop:getcwd))))
               (directory (and given (uiop:directory-exists-p given)))
               (target (and given (not directory)
                            (or (probe-file given) (expand-fail "~a does not exist" file)))))
          (when (and directory (or count only))
            (expand-fail "~:[--only~;--count~] needs a file, not the directory ~a" count file))
          (let* ((report (cond ((null json) (run-compass-check (or program (default-compass))))
                               ((string= json "-") (uiop:slurp-stream-string *standard-input*))
                               (t (or (and (probe-file json)
                                           (uiop:read-file-string json :external-format :utf-8))
                                      (expand-fail "~a does not exist" json)))))
                 (findings (report-findings report))
                 (selected (cond (target
                                  (remove-if-not (lambda (f) (same-file-p (short-finding-file f) target))
                                                 findings))
                                 (directory
                                  (remove-if-not (lambda (f)
                                                   (let ((true (probe-file (short-finding-file f))))
                                                     (and true (uiop:subpathp true directory))))
                                                 findings))
                                 (t findings))))
            (if (or count only)
                (expand-findings target selected
                                 (select-findings
                                  (remove nil selected :key #'short-finding-suggestion)
                                  :count count :offset (or offset 0) :skip skip :only only)
                                 :dry-run dry-run)
                (list-findings selected))))
        0)
    (expand-failure (e)
      (format *error-output* "~&expand-short-records: ~a~%" e)
      2)
    ;; Output cut off by a pipe, as by head: end quietly, as compass does.
    (stream-error (e)
      (if (eq (stream-error-stream e)
              (let ((stream *standard-output*))
                (loop while (typep stream 'synonym-stream)
                      do (setf stream (symbol-value (synonym-stream-symbol stream))))
                stream))
          (uiop:quit 141 nil)
          (error e)))))

(let ((arguments (uiop:command-line-arguments)))
  (if arguments
      (uiop:quit (expand-short-records-main arguments))
      (format t "~&;; expand-short-records loaded: call (expand-short-records-main '(\"FILE\" \"--count\" \"N\")), ~
                 or pass arguments after --end-toplevel-options.~%")))

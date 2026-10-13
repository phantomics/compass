;;;; expand-short-records.lisp — Write short record references, such as D6, as the full identifiers compass check suggests
;;;;
;;;; Read-if: expanding short record references before compass assign, or promoting this script to a command
;;;; See: COMPASS-DRAFT-toolchain-D26
;;;; Status: experimental
;;;; Invariant: writes only when given one file and a count, and then only the first COUNT findings in it
;;;; Invariant: writes nothing to a file unless every chosen finding still matches the file's text
;;;;
;;;; A standalone script, not part of the compass system. Run it from inside a
;;;; corpus:
;;;;
;;;;   sbcl --non-interactive --load src/expand-short-records.lisp \
;;;;        --end-toplevel-options PATH [--count N] [--dry-run] [--json REPORT] [--compass PROGRAM]
;;;;
;;;; With no --count it only lists, numbered in file order, the short references
;;;; `compass check` reports (rule ref/short-record) under PATH, a file or a
;;;; directory (`.` for the whole corpus), with the identifier each probably
;;;; means. With a FILE and --count N it rewrites the first N of them in
;;;; FILE, and with --dry-run as well it shows those N rewrites without writing.
;;;; The toolchain itself never rewrites a short reference (COMPASS-DRAFT-toolchain-D26),
;;;; because the suggestion is a guess from context; the count keeps a person
;;;; choosing how many guesses to accept, after reading the list.
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
      (format t "~&~%Expand the first N in a file with: FILE --count N (add --dry-run to preview).~%"))))

;;; Expanding

(defun expand-findings (file findings count &key dry-run)
  "Rewrite the first COUNT of FINDINGS that have a suggestion, all in FILE, as
their suggested identifiers; with DRY-RUN, only print what would change.
Refuses, writing nothing, if any of the chosen findings no longer matches."
  (let* ((suggested (remove nil findings :key #'short-finding-suggestion))
         (available (length suggested)))
    (when (> count available)
      (expand-fail "~a has ~d short reference~:p with a suggestion, fewer than --count ~d"
                   (uiop:native-namestring file) available count))
    (let* ((chosen (subseq suggested 0 count))
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
      (loop for finding in chosen for n from 1
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
                    (let ((n (- (length findings) available))) (and (plusp n) n))))))))

;;; Command line

(defparameter *expand-usage*
  "Usage: expand-short-records PATH [--count N] [--dry-run] [--json REPORT|-] [--compass PROGRAM]")

(defun parse-count (string)
  (let ((n (and string (ignore-errors (parse-integer string)))))
    (unless (and n (plusp n))
      (expand-fail "--count needs a positive integer, not ~s" string))
    n))

(defun expand-short-records-main (arguments)
  "Run the script on ARGUMENTS, a list of strings as on the command line, and
return the exit status: 0 on success, 2 on a usage error or refusal."
  (handler-case
      (let (file count dry-run json program)
        (loop while arguments
              do (let ((argument (pop arguments)))
                   (cond ((string= argument "--count") (setf count (parse-count (pop arguments))))
                         ((string= argument "--dry-run") (setf dry-run t))
                         ((string= argument "--json")
                          (setf json (or (pop arguments) (expand-fail "--json needs a file, or -"))))
                         ((string= argument "--compass")
                          (setf program (or (pop arguments) (expand-fail "--compass needs a program"))))
                         ((member argument '("-h" "--help") :test #'string=)
                          (format t "~a~%" *expand-usage*)
                          (return-from expand-short-records-main 0))
                         ((and (> (length argument) 1) (char= (char argument 0) #\-))
                          (expand-fail "unknown option ~a~%~a" argument *expand-usage*))
                         (file (expand-fail "give one path at a time~%~a" *expand-usage*))
                         (t (setf file argument)))))
        (when (and count (null file))
          (expand-fail "--count needs a FILE: expansion works on one file at a time"))
        (when (and dry-run (null count))
          (expand-fail "--dry-run previews a --count; without one, nothing is written anyway"))
        (let* ((given (and file (merge-pathnames file (uiop:getcwd))))
               (directory (and given (uiop:directory-exists-p given)))
               (target (and given (not directory)
                            (or (probe-file given) (expand-fail "~a does not exist" file)))))
          (when (and directory count)
            (expand-fail "--count needs a file, not the directory ~a" file))
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
            (if count
                (expand-findings target selected count :dry-run dry-run)
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

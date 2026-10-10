;;;; git.lisp — The Git layer: every call the toolchain makes to Git
;;;;
;;;; Read-if: running Git, reading a file at a revision, or adding a Git query
;;;; See: COMPASS-DRAFT-toolchain-D19, COMPASS-DRAFT-toolchain-D22
;;;; Invariant: Git is run with an argument list, never through a shell
;;;; Invariant: a missing Git signals git-unavailable; callers decide whether that is fatal
;;;; Concerns: security-boundary
;;;; Tests: tests/test-git.lisp

(in-package #:compass.git)

(defvar *git-program* "git"
  "The Git executable, found on the PATH unless this names a path.")

(define-condition git-unavailable (error)
  ((program :initarg :program :reader git-unavailable-program))
  (:report (lambda (c s)
             (format s "Git (~a) could not be run; install Git or put it on the PATH"
                     (git-unavailable-program c)))))

(define-condition git-error (error)
  ((arguments :initarg :arguments :reader git-error-arguments)
   (status :initarg :status :reader git-error-status)
   (output :initarg :output :reader git-error-output))
  (:report (lambda (c s)
             (format s "git ~{~a~^ ~} failed (exit ~a)~@[: ~a~]"
                     (git-error-arguments c) (git-error-status c)
                     (let ((text (trim-whitespace (or (git-error-output c) ""))))
                       (and (plusp (length text)) text))))))

(defun run-git (root arguments &key (check t))
  "Run Git in the directory ROOT with ARGUMENTS, a list of strings. Return its
standard output, its exit status, and its error output. With CHECK, a non-zero
exit signals GIT-ERROR. Signal GIT-UNAVAILABLE if Git cannot be run."
  (multiple-value-bind (output error-output status)
      (handler-case
          (uiop:run-program (list* *git-program* "-C" (uiop:native-namestring root)
                                   "-c" "core.quotepath=false" arguments)
                            :output :string :error-output :string
                            :ignore-error-status t :external-format :utf-8
                            :input nil)
        (error ()
          (error 'git-unavailable :program *git-program*)))
    (when (and check (/= status 0))
      (error 'git-error :arguments arguments :status status :output error-output))
    (values output status error-output)))

(defvar *availability* (make-hash-table :test #'equal))

(defun git-available-p ()
  "True if Git can be run."
  (multiple-value-bind (known present) (gethash *git-program* *availability*)
    (if present
        known
        (setf (gethash *git-program* *availability*)
              (handler-case (progn (run-git (uiop:getcwd) '("--version")) t)
                (git-unavailable () nil)
                (git-error () nil))))))

(defun first-line (text)
  (let ((line (subseq text 0 (or (position #\Newline text) (length text)))))
    (trim-whitespace line)))

(defun git-repository-p (root)
  "True if ROOT is inside a Git working tree. NIL, not an error, without Git."
  (and (git-available-p)
       (multiple-value-bind (output status)
           (run-git root '("rev-parse" "--is-inside-work-tree") :check nil)
         (and (zerop status) (string= (first-line output) "true")))))

(defun git-resolve (root revision)
  "The full commit SHA that REVISION names in the repository at ROOT, or NIL."
  (multiple-value-bind (output status)
      (run-git root (list "rev-parse" "--verify" "--quiet"
                          (concatenate 'string revision "^{commit}"))
               :check nil)
    (and (zerop status) (first-line output))))

(defun git-has-commits-p (root)
  (and (git-resolve root "HEAD") t))

(defun object-name (revision path)
  "The Git object name of PATH, relative to the directory Git runs in, at
REVISION."
  (format nil "~a:./~a" revision path))

(defun git-object-type (root revision path)
  "The type of PATH at REVISION: :FILE for a blob, :DIRECTORY for a tree, or NIL
if it does not exist there."
  (multiple-value-bind (output status)
      (run-git root (list "cat-file" "-t" (object-name revision path)) :check nil)
    (and (zerop status)
         (let ((type (first-line output)))
           (cond ((string= type "blob") :file)
                 ((string= type "tree") :directory)
                 (t nil))))))

(defun git-file-at (root revision path)
  "The text of the file PATH (relative to the repository root) at REVISION, or
NIL if it does not exist there."
  (and (eq (git-object-type root revision path) :file)
       (run-git root (list "cat-file" "-p" (object-name revision path)))))

(defun git-shallow-p (root)
  "True if the repository at ROOT is a shallow clone."
  (multiple-value-bind (output status)
      (run-git root '("rev-parse" "--is-shallow-repository") :check nil)
    (and (zerop status) (string= (first-line output) "true"))))

(defun git-attribute (root attribute path)
  "The value of the Git attribute ATTRIBUTE for PATH: a string such as
\"union\", or \"set\", \"unset\", or \"unspecified\"."
  (let* ((output (run-git root (list "check-attr" attribute "--" path)))
         (marker (format nil ": ~a: " attribute))
         (at (search marker output)))
    (if at
        (first-line (subseq output (+ at (length marker))))
        "unspecified")))

(defun git-tracked-files (root)
  "The paths of the files Git tracks in the repository at ROOT."
  (remove "" (uiop:split-string (run-git root '("ls-files" "-z"))
                                :separator (string (code-char 0)))
          :test #'string=))

(defparameter *hunk-scanner*
  (ppcre:create-scanner "^@@ -[0-9]+(?:,[0-9]+)? \\+([0-9]+)(?:,([0-9]+))? @@"))

(defun git-added-lines (root base path)
  "The line numbers of PATH, as it is in the working tree, that are added or
changed relative to the revision BASE. Return them as a sorted list, and a second
value that is true if PATH does not exist at BASE, in which case every line
counts as added."
  (if (null (git-object-type root base path))
      (values '() t)
      (let ((lines '()))
        (dolist (line (uiop:split-string
                       (run-git root (list "diff" "--no-color" "--no-ext-diff" "-U0"
                                           base "--" path))
                       :separator (string #\Newline)))
          (ppcre:register-groups-bind (start count) (*hunk-scanner* line)
            (let ((start (parse-integer start))
                  (count (if count (parse-integer count) 1)))
              (loop for n from start below (+ start count) do (push n lines)))))
        (values (sort lines #'<) nil))))

(defun git-identity (root)
  "The name of the person using Git at ROOT, as `git config user.name` gives it
and the repository's .mailmap canonicalises it; NIL if no name is configured."
  (let ((name (first-line (run-git root '("config" "user.name") :check nil)))
        (email (first-line (run-git root '("config" "user.email") :check nil))))
    (when (plusp (length name))
      (let ((mapped (first-line
                     (run-git root (list "check-mailmap"
                                         (format nil "~a <~a>" name
                                                 (if (plusp (length email))
                                                     email
                                                     "unknown@invalid")))
                              :check nil))))
        (let ((angle (position #\< mapped)))
          (if (and angle (plusp angle))
              (trim-whitespace (subseq mapped 0 angle))
              name))))))

(defparameter *default-bases* '("origin/HEAD" "origin/main" "origin/master")
  "Revisions tried, in order, when a command needs the branch a change will be
merged into and none was given.")

(defun git-default-base (root)
  "The first of *DEFAULT-BASES* that names a commit at ROOT, or NIL."
  (find-if (lambda (revision) (git-resolve root revision)) *default-bases*))

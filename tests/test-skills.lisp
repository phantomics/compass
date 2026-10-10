;;;; test-skills.lisp — The skills, templates, and AGENTS snippet agree with the toolchain
;;;;
;;;; The skills tell agents which `compass` commands to run and which rules the
;;;; toolchain applies. These tests fail when a skill names a command or a rule
;;;; that neither exists nor is planned, when a command is left undocumented, or
;;;; when a template, filled in, does not pass `compass check`.

(in-package #:compass.tests)

(def-suite skills :in compass)
(in-suite skills)

(defparameter *rule-token-scanner*
  (ppcre:create-scanner
   "^(?:file|manifest|fm|vocab|status|cite|id|register|memo|ref|git|ledger|index|catalog|map|header|dir|shape|a11y|review)/[a-z*-]*$")
  "Code spans that name a rule or a rule group.")

(defparameter *command-scanner* (ppcre:create-scanner "\\bcompass ([a-z][a-z-]*)")
  "A compass subcommand within code.")

(defun skill-files ()
  "The files that tell agents how to use the toolchain."
  (append (repository-markdown "skills/*/SKILL.md")
          (repository-markdown "skills/reference/*.md")
          (repository-markdown "templates/AGENTS.snippet.md")))

(defun code-texts (pathname)
  "The code in the Markdown file at PATHNAME: its code spans, and the lines of
its fenced blocks."
  (let ((document (read-document pathname :path (namestring pathname))))
    (append (mapcar #'code-span-text (document-code-spans document))
            (loop for fence in (document-fences document)
                  append (loop for line from (location-line fence)
                                 below (min (fence-end-line fence)
                                            (length (document-lines document)))
                               collect (aref (document-lines document) line))))))

(defun mentioned-rules (pathname)
  (remove-duplicates
   (remove-if-not (lambda (code) (ppcre:scan *rule-token-scanner* code))
                  (code-texts pathname))
   :test #'string=))

(defun mentioned-commands (pathname)
  (let ((commands '()))
    (dolist (code (code-texts pathname))
      (ppcre:do-register-groups (command) (*command-scanner* code)
        (pushnew command commands :test #'string=)))
    commands))

(defun repository-section (reference)
  "The text of the section REFERENCE (\"ID#anchor\") of this repository's corpus."
  (or (show (load-corpus (repository-root)) reference)
      (error "~a is not defined in this repository" reference)))

(defun planned-commands ()
  "The subcommands named in the toolchain plan's command-line section."
  (let ((commands '()))
    (ppcre:do-register-groups (command)
        (*command-scanner* (repository-section
                            "COMPASS-DRAFT-toolchain#command-line-interface"))
      (pushnew command commands :test #'string=))
    commands))

(defun planned-rules ()
  "The rule names and groups (`group/*`) in the toolchain plan's rule table."
  (let ((rules '()))
    (ppcre:do-register-groups (token)
        ("`([a-z0-9]+/[a-z*-]+)`" (repository-section
                                   "COMPASS-DRAFT-toolchain#validation-rules"))
      (pushnew token rules :test #'string=))
    rules))

(defun rule-known-p (token known)
  "True if TOKEN, a rule name or group, names a rule in KNOWN (names, and
groups written `group/*`)."
  (let ((group (subseq token 0 (1+ (position #\/ token))))
        (wildcard (or (ends-with-p "/" token) (ends-with-p "/*" token))))
    (some (lambda (name)
            (if wildcard
                (starts-with-p group name)
                (or (string= token name)
                    (and (ends-with-p "/*" name)
                         (starts-with-p (string-right-trim "*" name) token)))))
          known)))

(test planned-commands-and-rules-are-found
  "The plan sections the other tests compare against can be read."
  (is (member "assign" (planned-commands) :test #'string=))
  (is (member "outline" (planned-commands) :test #'string=))
  (is (member "ledger/append-only" (planned-rules) :test #'string=))
  (is (member "header/*" (planned-rules) :test #'string=)))

(test skills-name-only-known-commands
  (let ((known (append (command-names) (planned-commands))))
    (dolist (file (skill-files))
      (dolist (command (mentioned-commands file))
        (is (member command known :test #'string=)
            "~a names `compass ~a`, which is neither a command nor planned"
            (file-namestring file) command)))))

(test skills-name-only-known-rules
  (let ((known (append (mapcar #'rule-name (list-rules)) (planned-rules))))
    (dolist (file (skill-files))
      (dolist (rule (mentioned-rules file))
        (is (rule-known-p rule known)
            "~a names the rule `~a`, which is neither a rule nor planned"
            (file-namestring file) rule)))))

(test every-command-is-documented-for-the-skills
  (let ((documented (mentioned-commands
                     (merge-pathnames "skills/reference/toolchain.md" (repository-root)))))
    (dolist (command (command-names))
      (is (member command documented :test #'string=)
          "skills/reference/toolchain.md does not describe `compass ~a`" command))))

(test skills-use-the-toolchain
  "Each skill points at the shared toolchain reference; the three working
skills explain how to run it."
  (dolist (file (repository-markdown "skills/*/SKILL.md"))
    (let ((document (read-document file :path (namestring file)))
          (name (car (last (pathname-directory file)))))
      (is (search "../reference/toolchain.md" (document-text document))
          "~a does not refer to ../reference/toolchain.md" name)
      (unless (string= name "compass-derive")
        (is (member "using-the-toolchain" (document-anchors document) :test #'string=)
            "~a has no \"Using the toolchain\" section" name)
        (is (member "without-the-toolchain" (document-anchors document) :test #'string=)
            "~a has no \"Without the toolchain\" section" name)))))

;;; Filled-in templates pass compass check

(defparameter *template-fills*
  '(("<commit-pinned reference[^>]*>" . "`src/sample.lisp:frob@a1b2c3d`")
    ("<YYYY-MM-DD>" . "2026-10-08")
    ("<version>" . "1.0")
    ("<NAMESPACE>" . "TEST"))
  "Regular expressions for placeholders that need a particular kind of value,
and the values that replace them.")

(defun fill-template (text slug)
  "Fill in a template's placeholders as an author would, with document SLUG:
the namespace and slug, a self-reference for <ID>, values of the right form
where one is needed, and a word for every other placeholder. Lines the template
marks as applying only to a Superseded record are removed."
  (let ((text (format nil "~{~a~%~}"
                      (remove-if (lambda (line) (search "only with status Superseded" line))
                                 (coerce (split-lines text) 'list)))))
    (setf text (ppcre:regex-replace-all "<slug>" text slug)
          text (ppcre:regex-replace-all "<ID>" text
                                        (format nil "TEST-DRAFT-~a" slug)))
    (loop for (pattern . value) in *template-fills*
          do (setf text (ppcre:regex-replace-all pattern text value)))
    (ppcre:regex-replace-all "<(?!!--)[^<>\\n]*>" text "sample")))

(test filled-templates-pass-check
  "Each genre template, filled in and placed in the document directory, has no
errors; the only warnings are for vocabulary pending acceptance."
  (let ((files (loop for template in (repository-markdown "templates/*.template.md")
                     for genre = (subseq (file-namestring template) 0
                                         (search ".template.md" (file-namestring template)))
                     for slug = (format nil "sample-~(~a~)" genre)
                     collect (list (format nil "doc/~a.Sample.md" genre)
                                   (fill-template (read-text-file template) slug)))))
    (is (= 10 (length files)))
    ;; The documents are checked uncommitted, in a repository whose one commit
    ;; holds the code the Memo's basis cites.
    (with-git-repository (root (list (list "compass.sexp" "(:namespaces (\"TEST\"))")
                                     (list "src/sample.lisp" (lines "(defun frob ())"))))
      (let ((revision (trim-whitespace (git-in root "rev-parse" "--short" "HEAD"))))
        (loop for (path text) in files
              do (write-file root path (ppcre:regex-replace-all "a1b2c3d" text revision))))
      (let* ((corpus (load-corpus root))
             (findings (check-corpus corpus)))
      (is (= 10 (length (corpus-documents corpus))))
      (let ((errors (remove :warning findings :key #'finding-severity))
            (warnings (remove-if (lambda (f) (or (eq (finding-severity f) :error)
                                                 (string= (finding-rule f) "vocab/pending")))
                                 findings)))
        (is (null errors) (describe-findings errors))
        (is (null warnings) (describe-findings warnings)))))))

;;; Options

(defparameter *option-scanner* (ppcre:create-scanner "(?<![A-Za-z0-9-])--([a-z][a-z-]*)")
  "An option, such as --format, in code.")

(defun command-invocations (code)
  "The compass invocations in CODE, as (COMMAND OPTION...) lists. An invocation
runs from `compass COMMAND` to the end of the line, a pipe, a ; or && or ||, or
the next `compass`."
  (let ((invocations '()))
    (ppcre:do-scans (start end reg-starts reg-ends *command-scanner* code)
      (let* ((command (subseq code (aref reg-starts 0) (aref reg-ends 0)))
             (stop (or (ppcre:scan "[\\n|;&]|\\bcompass " code :start end) (length code)))
             (options '()))
        (ppcre:do-register-groups (option) (*option-scanner* (subseq code end stop))
          (pushnew option options :test #'string=))
        (push (cons command (nreverse options)) invocations)))
    (nreverse invocations)))

(test skills-use-only-real-options
  "Every option a skill passes to an implemented command is one that command
accepts, and every option written on its own exists on some command."
  (let ((all-options (remove-duplicates (mapcan (lambda (name)
                                                  (copy-list (command-option-names name)))
                                                (command-names))
                                        :test #'string=)))
    (dolist (file (skill-files))
      (dolist (code (code-texts file))
        (dolist (invocation (command-invocations code))
          (destructuring-bind (command &rest options) invocation
            (multiple-value-bind (accepted exists) (command-option-names command)
              (when exists
                (dolist (option options)
                  (is (member option accepted :test #'string=)
                      "~a passes --~a to `compass ~a`, which does not accept it"
                      (file-namestring file) option command))))))
        (ppcre:do-register-groups (option) ("^--([a-z][a-z-]*)$" (trim-whitespace code))
          (is (member option all-options :test #'string=)
              "~a names the option --~a, which no command accepts"
              (file-namestring file) option))))))

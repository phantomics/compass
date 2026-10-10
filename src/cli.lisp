;;;; cli.lisp — The compass command: argument parsing, subcommands, and the executable entry point
;;;;
;;;; Read-if: adding a subcommand or option, or changing exit codes
;;;; See: COMPASS-DRAFT-toolchain, COMPASS-DRAFT-toolchain-D19
;;;; Invariant: exit 0 on success, 1 on findings or a failed lookup, 2 on usage or internal error
;;;; Tests: tests/test-cli.lisp

(in-package #:compass.cli)

(defparameter +version+ "0.1.0")

(defvar *build-commit* nil
  "The commit this executable was built from, stamped by build.lisp.")

(define-condition usage-error (error)
  ((message :initarg :message :reader usage-error-message))
  (:report (lambda (c s) (write-string (usage-error-message c) s))))

(defun usage-error (control &rest args)
  (error 'usage-error :message (apply #'format nil control args)))

;;; Arguments

(defun parse-arguments (args options)
  "Split ARGS into positional arguments and an alist of options. OPTIONS is a
list of (NAME KIND), KIND being :flag, :value, or :list (repeatable, and
comma-separated)."
  (let ((positional '()) (values '()) (rest args))
    (loop while rest
          do (let ((arg (pop rest)))
               (cond
                 ((string= arg "--")
                  (setf positional (revappend rest positional) rest nil))
                 ((and (starts-with-p "--" arg) (> (length arg) 2))
                  (let* ((eq-pos (position #\= arg))
                         (name (subseq arg 2 eq-pos))
                         (inline (and eq-pos (subseq arg (1+ eq-pos))))
                         (spec (assoc name options :test #'string=)))
                    (unless spec (usage-error "unknown option --~a" name))
                    (ecase (second spec)
                      (:flag
                       (when inline (usage-error "--~a takes no value" name))
                       (push (cons name t) values))
                      ((:value :list)
                       (let ((value (or inline
                                        (if rest (pop rest)
                                            (usage-error "--~a needs a value" name)))))
                         (if (eq (second spec) :list)
                             (dolist (v (uiop:split-string value :separator ","))
                               (unless (string= v "") (push (cons name v) values)))
                             (push (cons name value) values)))))))
                 ((and (starts-with-p "-" arg) (> (length arg) 1))
                  (usage-error "unknown option ~a" arg))
                 (t (push arg positional)))))
    (values (nreverse positional) (nreverse values))))

(defun option (options name)
  (cdr (assoc name options :test #'string=)))

(defun option-list (options name)
  (loop for (key . value) in options when (string= key name) collect value))

(defun output-format (options)
  (let ((value (or (option options "format") "text")))
    (cond ((string= value "text") :text)
          ((string= value "json") :json)
          (t (usage-error "--format must be text or json, not ~s" value)))))

(defun repository-root (options)
  (let ((given (option options "root")))
    (if given
        (let ((dir (uiop:ensure-directory-pathname
                    (uiop:merge-pathnames* (uiop:parse-native-namestring given)
                                           (uiop:getcwd)))))
          (unless (uiop:directory-exists-p dir)
            (usage-error "--root ~a is not a directory" given))
          (uiop:ensure-directory-pathname (truename dir)))
        (uiop:ensure-directory-pathname (truename (find-repository-root (uiop:getcwd)))))))

(defun repository-path (argument root)
  "ARGUMENT, a path on the command line, as a repository-relative path; a
directory's path ends in /, and the root itself is \"\". Signal a usage error
for a path that does not exist or is outside the repository at ROOT."
  (let* ((pathname (uiop:merge-pathnames* (uiop:parse-native-namestring argument)
                                          (uiop:getcwd)))
         (directory (uiop:directory-exists-p (uiop:ensure-directory-pathname pathname)))
         (file (and (not directory) (uiop:file-exists-p pathname)))
         (true (cond (directory (truename directory))
                     (file (truename file))
                     (t (usage-error "no such file or directory: ~a" argument)))))
    (unless (or (uiop:pathname-equal true root) (uiop:subpathp true root))
      (usage-error "~a is outside the repository at ~a" argument
                   (uiop:native-namestring root)))
    (let ((relative (relative-path-string true root)))
      (if (or (string= relative "") (string= relative "./")) "" relative))))

(defun check-selected-paths (selected corpus)
  "Signal a usage error unless every repository-relative path in SELECTED is a
file the corpus considered, or a directory containing one."
  (let ((paths (corpus-paths corpus)))
    (dolist (path selected)
      (unless (or (string= path "")
                  (if (ends-with-p "/" path)
                      (some (lambda (p) (starts-with-p path p)) paths)
                      (member path paths :test #'string=)))
        (usage-error "~a ~:[is not a document of this corpus~;contains no documents of ~
                      this corpus~]: documents are the .md files under ~a, and .md files ~
                      at the repository root that open with front-matter"
                     path (ends-with-p "/" path)
                     (corpus-doc-directory corpus))))))

(defun load-corpus-for-command (root &key (skip-unmarked t))
  "Load the corpus at ROOT, warning on standard error if it holds no documents."
  (let ((corpus (load-corpus root :skip-unmarked skip-unmarked)))
    (when (corpus-empty-p corpus)
      (format *error-output* "compass: warning: no documents found under ~a in ~a; run ~
                              compass inside a Compass repository, or pass --root DIR~%"
              (corpus-doc-directory corpus) (uiop:native-namestring root)))
    corpus))

(defun base-revision (options root &key (option "base") default)
  "The revision named by the --base option, checked to exist in the Git
repository at ROOT, or DEFAULT (a function of ROOT, or NIL) when it is absent."
  (let ((given (option options option)))
    (cond
      ((null given) (and default (funcall default root)))
      ((not (git-available-p))
       (usage-error "--~a needs Git, which was not found on the PATH" option))
      ((not (git-repository-p root))
       (usage-error "--~a needs a Git repository; ~a is not in one" option
                    (uiop:native-namestring root)))
      ((not (git-resolve root given))
       (usage-error "--~a ~a does not name a commit in this repository" option given))
      (t given))))

(defun require-git (root command)
  "Signal a usage error unless Git can be used in the repository at ROOT."
  (cond ((not (git-available-p))
         (usage-error "compass ~a needs Git, which was not found on the PATH" command))
        ((not (git-repository-p root))
         (usage-error "compass ~a needs a Git repository; ~a is not in one" command
                      (uiop:native-namestring root)))))

(defun version-string ()
  (format nil "compass ~a (~@[commit ~a, ~]~a ~a, ~a ~a)"
          +version+ *build-commit*
          (lisp-implementation-type) (lisp-implementation-version)
          (string-downcase (software-type)) (string-downcase (machine-type))))

;;; Commands

(defstruct (command) name function synopsis summary options)

(defvar *commands* '())

(defmacro define-command (name (&key synopsis summary options) (args) &body body)
  `(setf *commands*
         (append (remove ,name *commands* :key #'command-name :test #'string=)
                 (list (make-command :name ,name :synopsis ,synopsis :summary ,summary
                                     :options ',options
                                     :function (lambda (,args) ,@body))))))

(defun find-command (name)
  (find name *commands* :key #'command-name :test #'string=))

(defun command-names ()
  "The names of the subcommands, in the order `compass help` lists them."
  (mapcar #'command-name *commands*))

(defun command-option-names (name)
  "The option names (without --) that the subcommand NAME accepts, or NIL with
a second value of NIL if there is no such subcommand."
  (let ((command (find-command name)))
    (values (mapcar #'first (and command (command-options command)))
            (and command t))))

(define-command "check"
    (:synopsis "check [PATH...] [--root DIR] [--format text|json] [--strict] [--skip-unmarked] [--rule NAME...] [--exclude NAME...] [--base REV]"
     :summary "Check the corpus against the standard; report findings"
     :options (("root" :value) ("format" :value) ("strict" :flag)
               ("skip-unmarked" :flag) ("rule" :list) ("exclude" :list)
               ("base" :value)))
    (args)
  (multiple-value-bind (paths options) (parse-arguments args (command-options (find-command "check")))
    (let* ((format (output-format options))
           (root (repository-root options))
           (only (option-list options "rule"))
           (exclude (option-list options "exclude"))
           (unknown (find-if-not (lambda (pattern)
                                   (some (lambda (rule) (rule-selected-p rule (list pattern) nil))
                                         (list-rules)))
                                 (append only exclude)))
           (selected (mapcar (lambda (p) (repository-path p root)) paths)))
      (when unknown (usage-error "no rule matches ~s; see `compass rules`" unknown))
      (let ((corpus (load-corpus-for-command
                     root :skip-unmarked (option options "skip-unmarked"))))
        (check-selected-paths selected corpus)
        (let* ((limit (and selected (not (member "" selected :test #'string=)) selected))
               (findings (check-corpus corpus :only only :exclude exclude :paths limit
                                              :base (base-revision options root)))
               (checked (and limit
                             (count-if (lambda (document)
                                         (some (lambda (p)
                                                 (or (string= p (document-path document))
                                                     (and (ends-with-p "/" p)
                                                          (starts-with-p
                                                           p (document-path document)))))
                                               limit))
                                       (corpus-documents corpus)))))
          (write-findings findings *standard-output* :format format :corpus corpus
                                                     :version +version+ :checked checked)
          (exit-code findings :strict (option options "strict")))))))

(define-command "show"
    (:synopsis "show ID[#ANCHOR] [--root DIR]"
     :summary "Print a document, one of its sections, or a record"
     :options (("root" :value)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "show")))
    (unless (= (length positional) 1) (usage-error "show takes one ID or ID#ANCHOR"))
    (let ((corpus (load-corpus-for-command (repository-root options)))
          (reference (first positional)))
      (multiple-value-bind (text path first last via) (show corpus reference)
        (cond
          (text
           (format *standard-output* "<!-- compass show ~a~@[ (an alias of ~a)~]: ~a, ~
                                      lines ~a-~a -->~%~a"
                   reference via path first last text)
           0)
          (t
           (format *error-output* "compass: ~a is not defined in this corpus~%" reference)
           1))))))

(define-command "index"
    (:synopsis "index [--namespace NS] [--stdout] [--root DIR]"
     :summary "Generate INDEX.md in the document directory"
     :options (("root" :value) ("namespace" :value) ("stdout" :flag)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "index")))
    (when positional (usage-error "index takes no arguments"))
    (let ((corpus (load-corpus-for-command (repository-root options)))
          (namespace (option options "namespace")))
      (cond
        ((option options "stdout")
         (write-string (generate-index corpus :namespace namespace) *standard-output*))
        ((null (corpus-documents corpus))
         (usage-error "no documents found, so no index was written; use --stdout to ~
                       preview one"))
        (t (format *standard-output* "Wrote ~a~%"
                   (write-index corpus :namespace namespace))))
      0)))

;;; outline and refs

(defun require-reference (positional command)
  "The single ID or ID#ANCHOR argument of COMMAND, checked for form."
  (unless (= (length positional) 1)
    (usage-error "~a takes one ID or ID#ANCHOR" command))
  (let ((reference (first positional)))
    (unless (parse-identifier (split-reference reference))
      (usage-error "~s is not a Compass identifier, such as COMPASS-0001, ~
                    COMPASS-DRAFT-toolchain, or COMPASS-DRAFT-toolchain-D5" reference))
    reference))

(defun json-object (&rest pairs)
  (let ((table (make-hash-table :test #'equal)))
    (loop for (key value) on pairs by #'cddr
          do (setf (gethash key table) (if (null value) :null value)))
    table))

(defun write-json-value (value)
  (let ((shasht:*write-indent-string* "  ")
        (*print-pretty* t))
    (shasht:write-json value *standard-output*)
    (terpri *standard-output*)))

(defun outline-json (outline)
  (json-object
   "id" (outline-id outline) "path" (outline-path outline)
   "title" (outline-title outline) "genre" (outline-genre outline)
   "status" (outline-status outline) "lines" (outline-total-lines outline)
   "front_matter" (and (outline-front-matter-end outline)
                       (json-object "start" 1 "end" (outline-front-matter-end outline)))
   "focus" (outline-focus outline) "record" (outline-record outline)
   "alias" (outline-alias outline)
   "sections" (coerce
               (mapcar (lambda (e)
                         (json-object "level" (outline-entry-level e)
                                      "text" (outline-entry-text e)
                                      "anchor" (outline-entry-anchor e)
                                      "start" (outline-entry-start e)
                                      "end" (outline-entry-end e)
                                      "lines" (1+ (- (outline-entry-end e)
                                                     (outline-entry-start e)))
                                      "record" (outline-entry-record e)))
                       (outline-entries outline))
               'vector)))

(defun write-outline-text (outline stream)
  (format stream "~a — ~a~%" (outline-id outline) (or (outline-title outline) "(untitled)"))
  (format stream "~a; ~@[~a, ~]~@[~a, ~]~d lines~@[; front-matter lines 1-~d~]~%"
          (outline-path outline) (outline-genre outline) (outline-status outline)
          (outline-total-lines outline) (outline-front-matter-end outline))
  (when (outline-alias outline)
    (format stream "~a is an alias of ~a in the ledger.~%" (outline-alias outline)
            (or (outline-record outline) (outline-id outline))))
  (when (outline-record outline)
    (format stream "Record ~a is at #~a.~%" (outline-record outline) (outline-focus outline)))
  (terpri stream)
  (let* ((digits (length (princ-to-string (outline-total-lines outline))))
         (range-width (1+ (* 2 digits))))
    (if (null (outline-entries outline))
        (format stream "(no headings)~%")
        (dolist (e (outline-entries outline))
          (let ((level (outline-entry-level e)))
            (format stream "~v@a ~v@a  ~a~a ~a  #~a~%"
                    range-width (format nil "~d-~d" (outline-entry-start e)
                                        (outline-entry-end e))
                    (+ digits 2) (format nil "(~d)" (1+ (- (outline-entry-end e)
                                                           (outline-entry-start e))))
                    (make-string (* 2 (1- level)) :initial-element #\Space)
                    (make-string level :initial-element #\#)
                    (outline-entry-text e) (outline-entry-anchor e)))))))

(define-command "outline"
    (:synopsis "outline ID[#ANCHOR] [--format text|json] [--root DIR]"
     :summary "List a document's headings, anchors, and line ranges"
     :options (("root" :value) ("format" :value)))
    (args)
  (multiple-value-bind (positional options)
      (parse-arguments args (command-options (find-command "outline")))
    (let* ((reference (require-reference positional "outline"))
           (format (output-format options))
           (corpus (load-corpus-for-command (repository-root options)))
           (outline (document-outline corpus reference)))
      (cond
        ((null outline)
         (format *error-output* "compass: ~a is not defined in this corpus~%" reference)
         1)
        ((eq format :json) (write-json-value (outline-json outline)) 0)
        (t (write-outline-text outline *standard-output*) 0)))))

(defparameter *reference-kinds*
  '((:relation "relation" "Front-matter relations")
    (:register "register" "Register listings")
    (:link "link" "Links")
    (:basis "basis" "Memo bases")
    (:mention "mention" "Mentions")))

(defun definition-description (definition definition-document)
  "Describe DEFINITION: return its kind as a JSON token, a phrase for text
output, its path, its line, and its host document's identifier."
  (etypecase definition
    (document (values "document" "document" (document-path definition) 1
                      (document-id definition)))
    (register-record
     (let ((host (record-document definition))
           (kind (record-kind definition)))
       (values (string-downcase (symbol-name kind))
               (format nil "~(~a~) record" (register-kind-label (find-register-kind kind)))
               (document-path host) (location-line definition) (document-id host))))
    (section
     (values "section" "section" (document-path definition-document)
             (location-line definition) (document-id definition-document)))))

(defun refs-json (reference references definition definition-document)
  (json-object
   "reference" reference
   "defined" (and definition
                  (multiple-value-bind (kind phrase path line host)
                      (definition-description definition definition-document)
                    (declare (ignore phrase))
                    (json-object "kind" kind "path" path "line" line "host" host)))
   "references" (coerce
                 (mapcar (lambda (r)
                           (json-object "kind" (second (assoc (inbound-reference-kind r)
                                                              *reference-kinds*))
                                        "path" (inbound-reference-path r)
                                        "line" (inbound-reference-line r)
                                        "column" (inbound-reference-column r)
                                        "field" (inbound-reference-field r)
                                        "text" (inbound-reference-text r)
                                        "source" (inbound-reference-source r)
                                        "alias" (inbound-reference-name r)))
                         references)
                 'vector)
   "summary" (json-object "references" (length references)
                          "documents" (length (remove-duplicates
                                               (mapcar #'inbound-reference-path references)
                                               :test #'string=)))))

(defun write-refs-text (reference references definition definition-document stream)
  (if definition
      (multiple-value-bind (kind phrase path line)
          (definition-description definition definition-document)
        (declare (ignore kind))
        (format stream "~a is a ~a defined at ~a:~d.~%" reference phrase path line))
      (format stream "~a is not defined in this corpus.~%" reference))
  (dolist (kind *reference-kinds*)
    (let ((group (remove (first kind) references :key #'inbound-reference-kind
                                                 :test-not #'eq)))
      (when group
        (format stream "~%~a (~d):~%" (third kind) (length group))
        (dolist (r group)
          (format stream "  ~a:~d~@[:~d~]  ~a~%" (inbound-reference-path r)
                  (inbound-reference-line r) (inbound-reference-column r)
                  (inbound-reference-text r))
          (when (inbound-reference-name r)
            (format stream "      (written with the alias ~a)~%"
                    (inbound-reference-name r)))))))
  (let ((documents (length (remove-duplicates (mapcar #'inbound-reference-path references)
                                              :test #'string=))))
    (if references
        (format stream "~%~d reference~:p in ~d document~:p.~%" (length references) documents)
        (format stream "~%No references.~%"))))

(define-command "refs"
    (:synopsis "refs ID[#ANCHOR] [--format text|json] [--root DIR]"
     :summary "List everything in the corpus that refers to an identifier"
     :options (("root" :value) ("format" :value)))
    (args)
  (multiple-value-bind (positional options)
      (parse-arguments args (command-options (find-command "refs")))
    (let* ((reference (require-reference positional "refs"))
           (format (output-format options))
           (corpus (load-corpus-for-command (repository-root options))))
      (multiple-value-bind (references definition definition-document)
          (find-references corpus reference)
        (if (eq format :json)
            (write-json-value (refs-json reference references definition
                                         definition-document))
            (write-refs-text reference references definition definition-document
                             *standard-output*))
        (cond ((or definition references) 0)
              (t (format *error-output* "compass: ~a is neither defined nor referenced in ~
                                         this corpus~%" reference)
                 1))))))

(defun parse-kind (name &key (allowed '("document" "decision" "open-question" "memo")))
  (let ((kind (and (member name allowed :test #'string=)
                   (cdr (assoc name '(("document" . :document) ("decision" . :decision)
                                      ("open-question" . :open-question) ("memo" . :memo))
                               :test #'string=)))))
    (or kind (usage-error "--kind must be ~{~a~^, ~}" allowed))))

(define-command "next"
    (:synopsis "next NAMESPACE [--kind document|decision|open-question|memo] [--base REV] [--root DIR], or next --in FILE --kind decision|open-question|memo"
     :summary "Preview the next number of a kind, or a document's next provisional record"
     :options (("root" :value) ("kind" :value) ("base" :value) ("in" :value)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "next")))
    (let* ((root (repository-root options))
           (in (option options "in")))
      (if in
          (progn
            (when positional (usage-error "next --in FILE takes no NAMESPACE"))
            (let ((kind (parse-kind (or (option options "kind") "")
                                    :allowed '("decision" "open-question" "memo")))
                  (corpus (load-corpus-for-command root))
                  (path (repository-path in root)))
              (check-selected-paths (list path) corpus)
              (handler-case
                  (progn (format *standard-output* "~a~%"
                                 (next-provisional-record corpus path kind))
                         0)
                (allocation-refused (e)
                  (format *error-output* "compass next: ~a~%" e)
                  1))))
          (progn
            (unless (= (length positional) 1) (usage-error "next takes one NAMESPACE"))
            (let ((namespace (first positional))
                  (kind (parse-kind (or (option options "kind") "document"))))
              (unless (ppcre:scan "^[A-Z][A-Z0-9]*$" namespace)
                (usage-error "~s is not a namespace; namespaces are uppercase, such as ~
                              COMPASS" namespace))
              (let* ((corpus (load-corpus-for-command root))
                     (base (base-revision options root
                                          :default (lambda (r)
                                                     (and (git-available-p)
                                                          (git-repository-p r)
                                                          (git-default-base r))))))
                (multiple-value-bind (id ledger-p)
                    (next-identifier corpus namespace kind :base base)
                  (format *standard-output* "~a~%" id)
                  (format *error-output*
                          "compass: a preview, from ~:[the identifiers defined in this ~
                           working tree (there is no ledger)~;the ledger~@[ here and at ~a~]~
                           ~]; numbers are taken by compass assign, and another branch may ~
                           take this one first~%"
                          ledger-p base))
                0)))))))

;;; Allocation

(defun kind-name (kind)
  (substitute #\Space #\- (string-downcase (symbol-name kind))))

(defun write-allocation-report (allocation stream &key dry-run corpus)
  "Describe ALLOCATION on STREAM. With CORPUS (the corpus after writing it),
also report what compass check, against the allocation's base revision, now
finds."
  (ecase (allocation-command allocation)
    (:assign
     (let ((document (allocation-document allocation)))
       (format stream "~:[Assigned~;Would assign~] numbers in ~a (status ~a):~%" dry-run
               (document-path document) (or (document-status document) "none"))))
    (:renumber
     (format stream "~:[Renumbered~;Would renumber~] against ~a:~%" dry-run
             (allocation-base allocation)))
    (:seed
     (format stream "~:[Created~;Would create~] the ledger with ~d entr~:@p:~%"
             dry-run (length (allocation-entries allocation)))))
  (let ((width (reduce #'max (allocation-mapping allocation)
                       :key (lambda (m) (length (first m))) :initial-value 0)))
    (dolist (m (allocation-mapping allocation))
      (format stream "  ~va  →  ~a  (~a)~%" width (first m) (second m) (kind-name (third m)))))
  (when (eq (allocation-command allocation) :seed)
    (dolist (entry (allocation-entries allocation))
      (format stream "  ~a  (~a)~%" (ledger-entry-id entry) (kind-name (ledger-entry-kind entry)))))
  (let ((rewrites (allocation-rewrites allocation)))
    (when rewrites
      (format stream "~:[Rewrote~;Would rewrite~] ~d line~:p in ~d document~:p: ~{~a~^, ~}.~%"
              dry-run
              (reduce #'+ rewrites :key (lambda (r) (length (rewrite-changed-lines r))))
              (length rewrites)
              (mapcar (lambda (r) (format nil "~a (~d)" (rewrite-path r)
                                          (length (rewrite-changed-lines r))))
                      rewrites))))
  (unless (eq (allocation-command allocation) :seed)
    (when (allocation-entries allocation)
      (format stream "~:[Appended~;Would append~] ~d entr~:@p to the ledger.~%" dry-run
              (length (allocation-entries allocation)))))
  (when (allocation-stale allocation)
    (format stream "Other tracked files still name the old identifiers. The ledger's ~
                    aliases keep them resolving; update them where it matters:~%")
    (dolist (s (allocation-stale allocation))
      (let ((text (third s)))
        (format stream "  ~a:~d  ~a~%" (first s) (second s)
                (if (> (length text) 100) (concatenate 'string (subseq text 0 99) "…") text)))))
  (dolist (w (allocation-warnings allocation))
    (format stream "Warning: ~a~:[.~;~]~%" w (find #\Newline w)))
  (when corpus
    (let ((errors (count :error (check-corpus corpus :base (allocation-base allocation))
                         :key #'finding-severity)))
      (if (zerop errors)
          (format stream "compass check finds no errors.~%")
          (format stream "compass check finds ~d error~:p; run it to see them.~%" errors))))
  (when dry-run
    (format stream "This was a dry run; nothing was written.~%")))

(defun run-allocation (command options root planner)
  "Load the corpus at ROOT, plan with PLANNER (a function of the corpus that
returns an ALLOCATION, or NIL when there is nothing to do), and write the plan
unless --dry-run. Report it on standard output."
  (require-git root command)
  (let ((corpus (load-corpus-for-command root)))
    (handler-case
        (let ((allocation (funcall planner corpus))
              (dry-run (option options "dry-run")))
          (cond
            ((null allocation)
             (format *standard-output* "Nothing to do.~%"))
            (dry-run
             (write-allocation-report allocation *standard-output* :dry-run t))
            (t
             (let ((fresh (execute-allocation corpus allocation)))
               (write-allocation-report allocation *standard-output* :corpus fresh))))
          0)
      (allocation-refused (e)
        (format *error-output* "compass ~a: ~a~%" command e)
        1))))

(define-command "assign"
    (:synopsis "assign FILE [--dry-run] [--force] [--base REV] [--root DIR]"
     :summary "Number an accepted document and its provisional records"
     :options (("root" :value) ("dry-run" :flag) ("force" :flag) ("base" :value)))
    (args)
  (multiple-value-bind (positional options)
      (parse-arguments args (command-options (find-command "assign")))
    (unless (= (length positional) 1) (usage-error "assign takes one FILE"))
    (let ((root (repository-root options)))
      (require-git root "assign")
      (let ((path (repository-path (first positional) root))
            (base (base-revision options root)))
        (run-allocation "assign" options root
                        (lambda (corpus)
                          (check-selected-paths (list path) corpus)
                          (plan-assign corpus path :base base
                                                   :force (option options "force"))))))))

(define-command "renumber"
    (:synopsis "renumber [--base REV] [--dry-run] [--root DIR]"
     :summary "After concurrent allocations, move this branch's numbers off taken ones"
     :options (("root" :value) ("dry-run" :flag) ("base" :value)))
    (args)
  (multiple-value-bind (positional options)
      (parse-arguments args (command-options (find-command "renumber")))
    (when positional (usage-error "renumber takes no arguments"))
    (let ((root (repository-root options)))
      (require-git root "renumber")
      (let ((base (base-revision options root :default #'git-default-base)))
        (run-allocation "renumber" options root
                        (lambda (corpus)
                          (let ((allocation (plan-renumber corpus :base base)))
                            (unless (and (null (allocation-mapping allocation))
                                         (null (allocation-entries allocation))
                                         (null (allocation-warnings allocation))
                                         (string= (allocation-ledger-text allocation)
                                                  (read-text-file
                                                   (corpus-ledger-pathname corpus))))
                              allocation))))))))

(define-command "init"
    (:synopsis "init --ledger [--dry-run] [--root DIR]"
     :summary "Create the ledger, seeded with the identifiers already in use"
     :options (("root" :value) ("ledger" :flag) ("dry-run" :flag)))
    (args)
  (multiple-value-bind (positional options)
      (parse-arguments args (command-options (find-command "init")))
    (when positional (usage-error "init takes no arguments"))
    (unless (option options "ledger")
      (usage-error "this version creates only the ledger, with compass init --ledger; ~
                    write compass.sexp by hand (COMPASS-DRAFT-toolchain-D4)"))
    (run-allocation "init" options (repository-root options) #'plan-seed)))

(define-command "rules"
    (:synopsis "rules [--format text|json]"
     :summary "List the rules, with their severities and the sections they enforce"
     :options (("format" :value)))
    (args)
  (multiple-value-bind (positional options) (parse-arguments args (command-options (find-command "rules")))
    (when positional (usage-error "rules takes no arguments"))
    (let ((rules (list-rules)))
      (ecase (output-format options)
        (:text
         (let ((width (reduce #'max rules :key (lambda (r) (length (rule-name r))))))
           (dolist (rule rules)
             (format *standard-output* "~va  ~7a  ~10a  ~a~%" width (rule-name rule)
                     (string-downcase (symbol-name (rule-severity rule)))
                     (or (rule-section rule) "")
                     (rule-summary rule)))))
        (:json
         (shasht:write-json
          (coerce (mapcar (lambda (rule)
                            (let ((table (make-hash-table :test #'equal)))
                              (setf (gethash "name" table) (rule-name rule)
                                    (gethash "severity" table)
                                    (string-downcase (symbol-name (rule-severity rule)))
                                    (gethash "section" table) (or (rule-section rule) :null)
                                    (gethash "scope" table)
                                    (string-downcase (symbol-name (rule-scope rule)))
                                    (gethash "summary" table) (rule-summary rule))
                              table))
                          rules)
                  'vector)
          *standard-output*)
         (terpri *standard-output*)))
      0)))

(define-command "version"
    (:synopsis "version" :summary "Print the version, build commit, and platform")
    (args)
  (when args (usage-error "version takes no arguments"))
  (format *standard-output* "~a~%" (version-string))
  0)

(defun print-help (stream)
  (format stream "Usage: compass COMMAND [ARGUMENTS]~%~%Commands:~%")
  (dolist (command *commands*)
    (format stream "  ~10a ~a~%" (command-name command) (command-summary command)))
  (format stream "~%Exit status: 0 success; 1 errors found or lookup failed; ~
                  2 usage or internal error.~%"))

(define-command "help"
    (:synopsis "help [COMMAND]" :summary "Show this help, or a command's synopsis")
    (args)
  (cond ((null args) (print-help *standard-output*) 0)
        ((find-command (first args))
         (let ((command (find-command (first args))))
           (format *standard-output* "Usage: compass ~a~%~%~a.~%"
                   (command-synopsis command) (command-summary command))
           0))
        (t (usage-error "unknown command ~s" (first args)))))

;;; Entry point

(defun run (args)
  (cond
    ((null args) (print-help *error-output*) 2)
    ((member (first args) '("-h" "--help") :test #'string=)
     (print-help *standard-output*) 0)
    ((member (first args) '("-V" "--version") :test #'string=)
     (format *standard-output* "~a~%" (version-string)) 0)
    (t
     (let ((command (find-command (first args))))
       (unless command (usage-error "unknown command ~s" (first args)))
       (funcall (command-function command) (rest args))))))

(defun output-closed-p (condition)
  "True if CONDITION reports that standard output was closed by its reader, as
when compass is piped into head."
  (and (typep condition 'stream-error)
       (or #+sbcl (typep condition 'sb-int:broken-pipe)
           (let ((stream (stream-error-stream condition)))
             (or (eq stream *standard-output*)
                 #+sbcl (eq stream sb-sys:*stdout*))))))

(defun main (&optional (args (uiop:command-line-arguments)) &key (exit t))
  "Run the compass command with ARGS. With EXIT (the default), exit the process
with the command's status; otherwise return it."
  (let ((code
          (handler-case
              (prog1 (run args)
                (finish-output *standard-output*))
            (usage-error (e)
              (format *error-output* "compass: ~a~%Run `compass help` for usage.~%" e)
              2)
            #+sbcl
            (sb-sys:interactive-interrupt ()
              (format *error-output* "~&compass: interrupted~%")
              130)
            (stream-error (e)
              (if (output-closed-p e)
                  141                   ; as if terminated by SIGPIPE, silently
                  (progn (format *error-output* "compass: internal error: ~a~%" e)
                         2)))
            (error (e)
              (format *error-output* "compass: internal error: ~a~%" e)
              2))))
    (ignore-errors (finish-output *error-output*))
    (if exit (uiop:quit code nil) code)))

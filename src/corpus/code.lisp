;;;; code.lisp — Code references in documents: finding them, and resolving them against Git
;;;;
;;;; Read-if: changing what counts as a code reference, or how a revision, path, or symbol is checked
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D28, COMPASS-DRAFT-toolchain-D29
;;;; Invariant: resolving every reference of a corpus takes two Git processes per repository
;;;; Invariant: a reference that cannot be checked is counted as unverified, never reported
;;;; Tests: tests/test-code-refs.lisp

(in-package #:compass.corpus)

;;; Finding code references

(defstruct (code-mention)
  document span text                    ; where, and the code span's content
  namespace path symbol                 ; [NS:]path[:symbol]
  line-start line-end                   ; #Lm[-Ln]
  line                                  ; a line written :42, which §9 writes #L42
  revision                              ; @revision, or NIL
  basis-p)                              ; true in the **Basis:** of a memo record

(defparameter *code-mention-scanner*
  (ppcre:create-scanner
   "^(?:([A-Z][A-Z0-9]*):)?([^\\s:@#()\\[\\]{}<>=,;'\"`*?|\\\\]+)(?::([^\\s@]+)|#L([0-9]+)(?:-L([0-9]+))?)?(?:@([0-9a-fA-F]{7,40}|[A-Za-z0-9][A-Za-z0-9._+/-]*))?$")
  "A code reference, pinned or not: [NS:]path[:symbol | #Lm[-Ln]][@revision].")

(defparameter *code-path-extensions*
  '("lisp" "asd" "lsp" "cl" "el" "scm" "ss" "rkt" "clj" "cljs" "cljc"
    "py" "js" "mjs" "cjs" "ts" "tsx" "jsx" "go" "rs" "c" "h" "cc" "cpp" "cxx"
    "hpp" "hh" "java" "kt" "rb" "sh" "bash" "zsh" "md" "sexp" "json" "yml"
    "yaml" "toml" "txt" "html" "css" "sql" "xml" "csv" "org")
  "Extensions that make a code span's path a path.")

(defun known-namespace-p (corpus namespace)
  "True if NAMESPACE is owned here, listed in the federation, or loaded."
  (or (corpus-owned-namespace-p corpus namespace)
      (and (find namespace (manifest-federation (corpus-manifest corpus))
                 :key #'federation-entry-namespace :test #'string=)
           t)
      (namespace-loaded-p corpus namespace)))

(defun path-extension (path)
  (let* ((name (subseq path (1+ (or (position #\/ path :from-end t) -1))))
         (dot (position #\. name :from-end t)))
    (and dot (plusp dot) (string-downcase (subseq name (1+ dot))))))

(defun path-like-p (corpus path)
  "True if PATH, from a code span, names a file or directory rather than
something else written with a colon or an at sign (D28)."
  (and (plusp (length path))
       (not (search "//" path))
       (or (find #\/ path)
           (member (path-extension path) *code-path-extensions* :test #'equal)
           (file-kind (corpus-root corpus) path))
       t))

(defun parse-code-mention (corpus text)
  "The parts of TEXT, a code span's content, as a code reference, or NIL. An
uppercase prefix is a namespace if it is a known one or the rest is a path;
otherwise it is read as the path, as in `README:install`."
  (flet ((scan (string)
           (ppcre:register-groups-bind (namespace path symbol start end revision)
               (*code-mention-scanner* string)
             (list namespace path symbol start end revision))))
    (let ((parts (scan text)))
      (when (and parts (first parts)
                 (not (known-namespace-p corpus (first parts)))
                 (not (path-like-p corpus (second parts))))
        (let ((colon (position #\: text)))
          (setf parts (let ((again (scan (subseq text (1+ colon)))))
                        (and again (null (first again)) (null (third again))
                             (null (fourth again))
                             (list nil (subseq text 0 colon) (second again)
                                   nil nil (sixth again)))))))
      (when parts
        (destructuring-bind (namespace path symbol start end revision) parts
          (when (or namespace (path-like-p corpus path))
            (let ((line (and symbol (every #'digit-char-p symbol) (parse-integer symbol))))
              (make-code-mention :text text :namespace namespace :path path
                                 :symbol (and (not line) symbol)
                                 :line-start (and start (parse-integer start))
                                 :line-end (and end (parse-integer end))
                                 :line line :revision revision))))))))

(defun code-mention-located-p (mention)
  "True if MENTION names a place in a file: a symbol or a line."
  (or (code-mention-symbol mention) (code-mention-line-start mention)
      (code-mention-line mention)))

(defun memo-basis-lines (document)
  (loop for record in (document-records document)
        for entry = (and (eq (record-kind record) :memo)
                         (record-field-entry record "Basis"))
        when entry collect (field-entry-line entry)))

(defun document-code-mentions (corpus document)
  "The code references in DOCUMENT's text and headings that are pinned or name
a location, as CODE-MENTIONs. Code spans that are not references, such as rule
names and bare file names, are left out."
  (corpus-cached
   corpus (list :code-mentions (document-path document))
   (lambda ()
     (let ((basis-lines (memo-basis-lines document)))
       (loop for span in (document-code-spans document)
             for mention = (parse-code-mention corpus (trim-whitespace (code-span-text span)))
             when (and mention (or (code-mention-revision mention)
                                   (code-mention-located-p mention)))
               collect (progn (setf (code-mention-document mention) document
                                    (code-mention-span mention) span
                                    (code-mention-basis-p mention)
                                    (and (member (location-line span) basis-lines) t))
                              mention))))))

;;; Which repository a reference is read in

(defun code-mention-root (corpus mention)
  "The root of the repository MENTION is read in, or NIL if it is in a
namespace that is not loaded."
  (namespace-root corpus (code-mention-namespace mention)))

;;; Resolving

(defun repository-shallow-p (corpus root)
  (corpus-cached corpus (list :shallow (uiop:native-namestring root))
                 (lambda () (git-shallow-p root))))

(defun revision-table (corpus root)
  (corpus-cached corpus (list :revisions (uiop:native-namestring root))
                 (lambda () (make-hash-table :test #'equal))))

(defun ensure-revisions (corpus root revisions &optional objects)
  "Look up the REVISIONS not yet known for ROOT, and the types of the object
names OBJECTS, in one Git process. Return the revision table, and a hash table
of the OBJECTS' types."
  (let* ((table (revision-table corpus root))
         (unknown (remove-duplicates
                   (remove-if (lambda (r) (nth-value 1 (gethash r table))) revisions)
                   :test #'string=))
         (types (git-object-types root (append (mapcar (lambda (r) (format nil "~a^{commit}" r))
                                                       unknown)
                                               objects)))
         (object-types (make-hash-table :test #'equal)))
    (loop for revision in unknown
          for type in types
          do (setf (gethash revision table) type))
    (loop for name in objects
          for type in (nthcdr (length unknown) types)
          do (setf (gethash name object-types) type))
    (values table object-types)))

(defun revision-status (corpus namespace revision)
  "Whether REVISION exists in the repository of NAMESPACE (NIL for this one):
:EXISTS, :MISSING, :AMBIGUOUS, or :UNKNOWN when Git cannot tell (no Git, no
loaded repository, or a revision missing from a shallow clone)."
  (let ((root (namespace-root corpus namespace)))
    (if (not (and root (repository-usable-p corpus root)))
        :unknown
        (let ((type (gethash revision (ensure-revisions corpus root (list revision)))))
          (cond ((eq type :commit) :exists)
                ((eq type :ambiguous) :ambiguous)
                ((repository-shallow-p corpus root) :unknown)
                (t :missing))))))

(defun resolve-code-mentions (corpus)
  "Resolve every pinned code reference of CORPUS. Return a hash table from each
CODE-MENTION to a list: (:ok), (:unverified), (:no-git ROOT),
(:missing-revision), (:ambiguous-revision), (:missing-path), (:directory),
(:missing-symbol), or (:beyond-end LINES)."
  (corpus-cached
   corpus :code-resolution
   (lambda ()
     (let ((results (make-hash-table :test #'eq))
           (by-root (make-hash-table :test #'equal)))
       ;; Group the pinned references by the repository they are read in.
       (dolist (document (corpus-documents corpus))
         (dolist (mention (document-code-mentions corpus document))
           (when (code-mention-revision mention)
             (let ((root (code-mention-root corpus mention)))
               (if root
                   (push mention (gethash (uiop:native-namestring root) by-root))
                   (setf (gethash mention results) (list :unverified)))))))
       (maphash
        (lambda (key mentions)
          (let ((root (uiop:parse-native-namestring key :ensure-directory t)))
            (if (not (repository-usable-p corpus root))
                (dolist (m mentions) (setf (gethash m results) (list :no-git root)))
                (flet ((object-name (m) (format nil "~a:~a" (code-mention-revision m)
                                                (code-mention-path m))))
                  ;; One process finds the revisions, and the paths of references
                  ;; that name no place in the file; another reads the files the
                  ;; rest name a symbol or lines in.
                  (multiple-value-bind (revisions path-types)
                      (ensure-revisions corpus root (mapcar #'code-mention-revision mentions)
                                        (remove-duplicates
                                         (mapcar #'object-name
                                                 (remove-if #'code-mention-located-p mentions))
                                         :test #'string=))
                    (let* ((shallow (repository-shallow-p corpus root))
                           (wanted (remove-duplicates
                                    (loop for m in mentions
                                          when (and (code-mention-located-p m)
                                                    (eq (gethash (code-mention-revision m)
                                                                 revisions)
                                                        :commit))
                                            collect (object-name m))
                                    :test #'string=))
                           (objects (make-hash-table :test #'equal)))
                      (loop for name in wanted
                            for object in (git-read-objects root wanted)
                            do (setf (gethash name objects) object))
                      (maphash (lambda (name type)
                                 (unless (gethash name objects)
                                   (setf (gethash name objects) (cons type nil))))
                               path-types)
                      (dolist (m mentions)
                        (setf (gethash m results)
                              (let ((type (gethash (code-mention-revision m) revisions)))
                                (cond
                                  ((eq type :ambiguous) (list :ambiguous-revision))
                                  ((not (eq type :commit))
                                   (if shallow (list :unverified) (list :missing-revision)))
                                  (t (check-code-object
                                      m (gethash (object-name m) objects)))))))))))))
        by-root)
       results))))

(defun check-code-object (mention object)
  "The result for MENTION, whose revision exists, given OBJECT, the (TYPE . TEXT)
of its path at that revision."
  (destructuring-bind (&optional type . text) object
    (cond
      ((null type) (list :missing-path))
      ((not (eq type :blob))
       (if (code-mention-located-p mention) (list :directory) (list :ok)))
      ((null text) (list :ok))            ; not text, or not read: its path exists
      (t
       (let ((lines (line-count text))
             (last-line (or (code-mention-line-end mention) (code-mention-line-start mention)
                            (code-mention-line mention))))
         (cond
           ((and last-line (> last-line lines)) (list :beyond-end lines))
           ((and (code-mention-symbol mention)
                 (not (symbol-defined-p (code-mention-path mention)
                                        (code-mention-symbol mention) text)))
            (list :missing-symbol))
           (t (list :ok))))))))

(defun line-count (text)
  "The number of lines in TEXT, a final line without a newline included."
  (let ((text (coerce text 'simple-string)) (n 0))
    (declare (type simple-string text) (type fixnum n))
    (dotimes (i (length text))
      (when (char= (schar text i) #\Newline) (incf n)))
    (if (and (plusp (length text)) (char/= (schar text (1- (length text))) #\Newline))
        (1+ n)
        n)))

;;; Finding a symbol (D28)

(defparameter *lisp-extensions*
  '("lisp" "asd" "lsp" "cl" "el" "scm" "ss" "rkt" "clj" "cljs" "cljc"))

(defparameter *name* "([^\\s()\"']+)"
  "The capture group for a defined name in the definition patterns.")

(defparameter *lisp-definition-scanners*
  (list (ppcre:create-scanner
         "\\((?:[^\\s():]+:{1,2})?(?:def\\S*|define\\S*|test)\\s+\\(?['\"#:]*([^\\s()\"']+)"
         :case-insensitive-mode t)
        (ppcre:create-scanner ":(?:reader|writer|accessor)\\s+([^\\s()\"']+)"
                              :case-insensitive-mode t))
  "Lisp definition forms, each capturing the name defined: (def… NAME,
(define-… \"NAME\", FiveAM's (test NAME, and slot readers and accessors.")

(defparameter *definition-scanners*
  (mapcar
   (lambda (entry)
     (cons (first entry)
           (mapcar (lambda (pattern) (ppcre:create-scanner pattern :multi-line-mode t))
                   (rest entry))))
   '((("py") "^\\s*(?:async\\s+)?(?:def|class)\\s+(\\w+)" "^(\\w+)\\s*(?::[^=\\n]*)?=")
     (("js" "mjs" "cjs" "ts" "tsx" "jsx")
      "\\b(?:function\\*?|class|interface|type|enum|const|let|var)\\s+([\\w$]+)"
      "^\\s*(?:(?:export|default|async|static|public|private|protected|readonly|get|set)\\s+)*([\\w$]+)\\s*[(=:<]")
     (("go") "^func\\s+(?:\\([^)]*\\)\\s*)?(\\w+)" "^\\s*(?:type|var|const)\\s+(\\w+)")
     (("rs") "\\b(?:fn|struct|enum|trait|type|mod|const|static|union|macro_rules!)\\s+(\\w+)")
     (("c" "h" "cc" "cpp" "cxx" "hpp" "hh")
      "^\\s*#\\s*define\\s+(\\w+)" "\\b(?:struct|union|enum|class|typedef)\\b[^;\\n]*?\\b(\\w+)\\s*[{;]"
      "^[A-Za-z_][\\w \\t*&:<>,]*?\\b(\\w+)\\s*\\([^;\\n]*$")
     (("sh" "bash" "zsh") "^\\s*(?:function\\s+)?([\\w-]+)\\s*\\(\\s*\\)" "^\\s*function\\s+([\\w-]+)")))
  "Definition patterns by file extension, each capturing the name defined.")

(defun find-substring (needle text start &optional case-insensitive)
  "The position of NEEDLE in TEXT at or after START, or NIL."
  (declare (type simple-string needle text) (type fixnum start))
  (let ((n (length needle)) (m (length text)))
    (when (zerop n) (return-from find-substring nil))
    (loop for i of-type fixnum from start to (- m n)
          when (loop for j of-type fixnum from 0 below n
                     always (if case-insensitive
                                (char-equal (schar needle j) (schar text (+ i j)))
                                (char= (schar needle j) (schar text (+ i j)))))
            return i)))

(defun line-bounds (text at)
  (values (1+ (or (position #\Newline text :end at :from-end t) -1))
          (or (position #\Newline text :start at) (length text))))

(defun occurrences (text needle &optional case-insensitive)
  "Each occurrence of NEEDLE in TEXT, as (POSITION LINE-START LINE-END)."
  (let ((text (coerce text 'simple-string))
        (needle (coerce needle 'simple-string))
        (found '()))
    (loop with start = 0
          for at = (find-substring needle text start case-insensitive)
          while at
          do (multiple-value-bind (s e) (line-bounds text at)
               (push (list at s e) found)
               (setf start (1+ at))))
    (nreverse found)))

(defun line-defines-p (text line-start line-end scanners name test)
  "True if a definition pattern in SCANNERS, run over one line of TEXT,
captures NAME (compared with TEST)."
  (let ((line (subseq text line-start line-end)))
    (some (lambda (scanner)
            (ppcre:do-register-groups (defined) (scanner line nil)
              (when (funcall test defined name) (return t))))
          scanners)))

(defun token-at-p (text at length)
  "True if the LENGTH characters of TEXT at AT are a whole token."
  (flet ((word-char-p (c) (or (alphanumericp c) (member c '(#\_ #\-)))))
    (and (or (zerop at) (not (word-char-p (char text (1- at)))))
         (or (= (+ at length) (length text))
             (not (word-char-p (char text (+ at length))))))))

(defun symbol-defined-p (path symbol text)
  "True if TEXT, the file at PATH, defines SYMBOL: by a Lisp definition form, by
a definition pattern of the file's language, or, in a file of any other
language, by containing SYMBOL as a whole token. Only lines containing the
symbol are scanned."
  (let* ((extension (path-extension path))
         (lisp-p (member extension *lisp-extensions* :test #'equal))
         (patterns (and (not lisp-p)
                        (rest (find-if (lambda (entry) (member extension (first entry)
                                                              :test #'equal))
                                       *definition-scanners*)))))
    (cond
      (lisp-p
       (let ((name (subseq symbol (1+ (or (position #\: symbol :from-end t) -1)))))
         (some (lambda (occurrence)
                 (destructuring-bind (at s e) occurrence
                   (declare (ignore at))
                   (line-defines-p text s e *lisp-definition-scanners* name #'string-equal)))
               (occurrences text name t))))
      (patterns
       (let ((name (car (last (ppcre:split "::|\\.|#" symbol)))))
         (and name
              (some (lambda (occurrence)
                      (destructuring-bind (at s e) occurrence
                        (declare (ignore at))
                        (line-defines-p text s e patterns name #'string=)))
                    (occurrences text name)))))
      (t
       (some (lambda (occurrence) (token-at-p text (first occurrence) (length symbol)))
             (occurrences text symbol))))))

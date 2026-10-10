;;;; allocate.lisp — Allocating numbers: assign, renumber, seed the ledger, and suggest the next identifier
;;;;
;;;; Read-if: changing how numbers are chosen, what assign or renumber does, or how the ledger is seeded
;;;; See: COMPASS-DRAFT-toolchain-D9, COMPASS-DRAFT-toolchain-D22, COMPASS-DRAFT-toolchain-D23
;;;; See: COMPASS-DRAFT-toolchain-D24, COMPASS-DRAFT-toolchain-D25
;;;; Invariant: planning writes nothing; execute-allocation writes the plan, and nothing else
;;;; Invariant: a number already in the ledger, here or at the base revision, is never chosen again
;;;; Concerns: persistent-format
;;;; Tests: tests/test-allocate.lisp, tests/test-concurrency.lisp

(in-package #:compass.corpus)

(define-condition allocation-refused (error)
  ((message :initarg :message :reader allocation-refused-message))
  (:report (lambda (c s) (write-string (allocation-refused-message c) s))))

(defun refuse (control &rest arguments)
  (error 'allocation-refused :message (apply #'format nil control arguments)))

(defparameter +accepted-statuses+ '("Accepted" "Implemented" "Design-Record" "Current")
  "The statuses at which a document is assigned a number (§6, §13).")

(defstruct (allocation)
  command                               ; :assign, :renumber, or :seed
  document                              ; the document assigned, for :assign
  (mapping '())                         ; (old new kind) for each identifier changed
  (entries '())                         ; ledger entries added
  ledger-text                           ; the ledger's new text
  (rewrites '())                        ; REWRITEs of corpus documents
  (stale '())                           ; (path line text) in other tracked files
  (warnings '())
  base)                                 ; the base revision consulted, or NIL

;;; Numbers

(defun base-ledger-entries (corpus base)
  "The well-formed entries of the ledger at the revision BASE, or NIL."
  (let ((root (corpus-root corpus)))
    (when (and base (git-available-p) (git-repository-p root))
      (let ((text (git-file-at root base (corpus-ledger-path corpus))))
        (and text (values (parse-ledger-text text)))))))

(defun corpus-used-identifiers (corpus)
  "Every canonical identifier the documents define or list in front-matter."
  (let ((ids '()))
    (dolist (definition (canonical-definitions corpus))
      (push (first definition) ids))
    (dolist (document (corpus-documents corpus))
      (dolist (field (append '("relates-to" "supersedes" "superseded-by")
                             (mapcar #'register-kind-field (register-kinds))))
        (dolist (id (node-identifiers (document-field-node document field)))
          (push id ids))))
    ids))

(defun used-serials (corpus namespace kind &key base-entries extra-ids)
  "The numbers of KIND in NAMESPACE that are taken: in the ledger, in
BASE-ENTRIES, among the identifiers the documents use, and in EXTRA-IDS."
  (let ((serials '()))
    (flet ((consider (id)
             (let ((parsed (parse-identifier id)))
               (when (and parsed (not (identifier-provisional-p parsed))
                          (string= (identifier-namespace parsed) namespace)
                          (eq (identifier-kind parsed) kind))
                 (push (identifier-serial parsed) serials)))))
      (let ((ledger (corpus-ledger corpus)))
        (when ledger (mapc (lambda (e) (consider (ledger-entry-id e))) (ledger-entries ledger))))
      (mapc (lambda (e) (consider (ledger-entry-id e))) base-entries)
      (mapc #'consider (corpus-used-identifiers corpus))
      (mapc #'consider extra-ids))
    serials))

(defun make-counter (corpus namespace base-entries &optional extra-ids)
  "A function of a kind that returns the next free number of that kind in
NAMESPACE each time it is called."
  (let ((next (make-hash-table)))
    (lambda (kind)
      (let ((n (or (gethash kind next)
                   (1+ (reduce #'max (used-serials corpus namespace kind
                                                   :base-entries base-entries
                                                   :extra-ids extra-ids)
                               :initial-value 0)))))
        (setf (gethash kind next) (1+ n))
        (format-canonical-identifier namespace kind n)))))

(defun next-identifier (corpus namespace kind &key base)
  "Preview the next canonical identifier of KIND in NAMESPACE, without
allocating it: one more than the highest number in the ledger, in the ledger at
the revision BASE, and among the identifiers the documents use. Return the
identifier, and true if the repository has a ledger. Either way the answer is a
preview: another branch may take the number before this one merges."
  (values (funcall (make-counter corpus namespace (base-ledger-entries corpus base)) kind)
          (and (corpus-ledger corpus) t)))

;;; Who and where

(defun allocator (corpus)
  (let ((name (git-identity (corpus-root corpus))))
    (unless name
      (refuse "Git has no user.name here; set one with git config user.name, so the ~
               ledger can record who allocated each number"))
    name))

(defun require-ledger-namespaces (corpus)
  (unless (and (manifest-path (corpus-manifest corpus))
               (manifest-namespaces (corpus-manifest corpus)))
    (refuse "this repository's compass.sexp does not declare the namespaces it owns ~
             (:namespaces), so no number can be allocated here")))

(defun ledger-problems (corpus)
  "The errors in the ledger's own lines and duplicates."
  (remove-if-not (lambda (f) (and (eq (finding-severity f) :error)
                                  (equal (finding-path f) (corpus-ledger-path corpus))))
                 (corpus-load-findings corpus)))

(defun duplicate-ledger-ids (ledger)
  (let ((seen (make-hash-table :test #'equal)) (duplicates '()))
    (dolist (entry (and ledger (ledger-entries ledger)))
      (if (gethash (ledger-entry-id entry) seen)
          (pushnew (ledger-entry-id entry) duplicates :test #'string=)
          (setf (gethash (ledger-entry-id entry) seen) t)))
    duplicates))

;;; Other files that name the old identifiers

(defparameter *stale-scan-limit* (* 2 1024 1024)
  "Tracked files larger than this many bytes are not searched.")

(defun stale-mentions (corpus olds)
  "Lines of tracked files outside the corpus that name an identifier in OLDS, as
(PATH LINE TEXT)."
  (let ((root (corpus-root corpus))
        (skip (list* (corpus-ledger-path corpus) (index-relative-path corpus)
                     (mapcar #'document-path (corpus-documents corpus))))
        (found '()))
    (when (and olds (git-available-p) (git-repository-p root))
      (dolist (path (git-tracked-files root))
        (unless (member path skip :test #'string=)
          (let ((pathname (root-file root path)))
            (when (and (uiop:file-exists-p pathname)
                       (<= (or (ignore-errors
                                (with-open-file (in pathname :element-type '(unsigned-byte 8))
                                  (file-length in)))
                               0)
                           *stale-scan-limit*))
              (let ((text (handler-case (read-text-file pathname)
                            (text-file-error () nil))))
                (when (and text (not (find (code-char 0) text))
                           (some (lambda (old) (search old text)) olds))
                  (loop for line across (split-lines text)
                        for number from 1
                        when (intersection olds (find-identifiers-in-text line)
                                           :test #'string=)
                          do (push (list path number (trim-whitespace line)) found)))))))))
    (nreverse found)))

;;; assign

(defun base-or-default (corpus base)
  "BASE, or else the remote's default branch, or NIL if there is none."
  (or base (git-default-base (corpus-root corpus))))

(defun plan-assign (corpus path &key base force (today (today)))
  "Plan assigning numbers to the document at the repository-relative PATH and to
its provisional records (D24). Return an ALLOCATION; signal ALLOCATION-REFUSED
when assigning is not allowed."
  (require-ledger-namespaces corpus)
  (let* ((document (document-at-path corpus path))
         (ledger (corpus-ledger corpus)))
    (unless (and document (member document (corpus-documents corpus)))
      (refuse "~a is not a document of this corpus" path))
    (unless (document-front-matter document)
      (refuse "~a has front-matter the toolchain cannot read; run compass check" path))
    (let* ((id (document-id document))
           (identifier (parse-identifier id)))
      (unless (and identifier (identifier-document-p identifier))
        (refuse "~a declares no valid document identifier" path))
      (let ((namespace (identifier-namespace identifier)))
        (unless (corpus-owned-namespace-p corpus namespace)
          (refuse "~a is in the ~a namespace, which compass.sexp does not list under ~
                   :namespaces" id namespace))
        (let ((status (document-status document)))
          (unless (or force (member status +accepted-statuses+ :test #'string=))
            (refuse "~a has the status ~a; a document is assigned a number once it is ~
                     ~{~a~^, ~} (a person sets that status), or with --force"
                    id (or status "(none)") +accepted-statuses+)))
        (let ((problems (ledger-problems corpus))
              (duplicates (duplicate-ledger-ids ledger)))
          (when problems
            (refuse "the ledger has ~a error~:p; fix ~:*~[~;it~:;them~] first (compass check ~
                     ~a)" (length problems) (corpus-ledger-path corpus)))
          (when duplicates
            (refuse "the ledger allocates ~{~a~^, ~} more than once; run compass renumber"
                    duplicates)))
        (let* ((by (allocator corpus))
               (base (base-or-default corpus base))
               (base-entries (base-ledger-entries corpus base))
               (next (make-counter corpus namespace base-entries))
               (mapping '()) (entries '())
               (new-id (if (identifier-provisional-p identifier)
                           (funcall next :document)
                           id)))
          (when (identifier-provisional-p identifier)
            (let ((assigned (ledger-alias-entry ledger id)))
              (when assigned
                (refuse "~a was already assigned ~a (~a line ~a)" id
                        (ledger-entry-id assigned) (ledger-path ledger)
                        (ledger-entry-line assigned))))
            (push (list id new-id :document) mapping)
            (push (make-ledger-entry :id new-id :kind :document :draft id :path path
                                     :date today :by by)
                  entries))
          (dolist (record (document-records document))
            (let ((rid (record-identifier record)))
              (when (and (identifier-provisional-p rid)
                         (not (and (eq (record-kind record) :memo)
                                   (equal (record-field record "Status") "Draft"))))
                (let ((assigned (ledger-alias-entry ledger (record-id record))))
                  (when assigned
                    (refuse "~a was already assigned ~a (~a line ~a)" (record-id record)
                            (ledger-entry-id assigned) (ledger-path ledger)
                            (ledger-entry-line assigned))))
                (let ((new (funcall next (record-kind record))))
                  (push (list (record-id record) new (record-kind record)) mapping)
                  (push (make-ledger-entry :id new :kind (record-kind record)
                                           :draft (record-id record) :host new-id
                                           :date today :by by)
                        entries)))))
          (setf mapping (nreverse mapping) entries (nreverse entries))
          (unless mapping
            (refuse "~a already has a number and defines no provisional record to number"
                    id))
          (let ((shorts (short-references-to corpus (mapcar #'first mapping))))
            (when (and shorts (not force))
              (refuse "~d short reference~:p would change meaning once these records are ~
                       numbered; write ~:*~[~;it~:;them~] as full identifiers first (or ~
                       assign with --force):~%~a"
                      (length shorts) (format-short-references shorts)))
          (make-allocation
           :command :assign :document document :mapping mapping :entries entries
           :ledger-text (ledger-text-with-entries (and ledger (ledger-text ledger)) entries
                                                  :namespaces (manifest-namespaces
                                                               (corpus-manifest corpus)))
           :rewrites (plan-rewrites
                      corpus (mapcar (lambda (m) (cons (first m) (second m))) mapping))
           :stale (stale-mentions corpus (mapcar #'first mapping))
           :warnings (append
                      (short-reference-warnings shorts)
                      (unless base
                        (list (format nil "no base revision was found (origin/HEAD, origin/main, or ~
                               origin/master), so only this working tree's ledger was ~
                               consulted; pass --base to name the branch you will merge ~
                               into")))
                      (unless (member (document-status document) +accepted-statuses+
                                      :test #'string=)
                        (list (format nil "~a has the status ~a; assigned with --force"
                                      id (document-status document)))))
           :base base)))))))

;;; seed

(defun plan-seed (corpus &key (today (today)))
  "Plan creating the ledger with an entry for every canonical identifier the
documents already define in the namespaces this repository owns (D9)."
  (require-ledger-namespaces corpus)
  (when (corpus-ledger corpus)
    (refuse "~a already exists" (corpus-ledger-path corpus)))
  (let* ((by (allocator corpus))
         (definitions (remove-if-not
                       (lambda (d) (corpus-owned-namespace-p
                                    corpus (identifier-namespace (parse-identifier (first d)))))
                       (canonical-definitions corpus)))
         (counts (make-hash-table :test #'equal)))
    (dolist (definition definitions) (incf (gethash (first definition) counts 0)))
    (let ((duplicates (loop for id being the hash-keys of counts using (hash-value n)
                            when (> n 1) collect id)))
      (when duplicates
        (refuse "~{~a~^, ~} ~:[is~;are~] defined in more than one place; give the copies ~
                 provisional identifiers (<NS>-DRAFT-<slug>-O<n>) before seeding the ledger"
                (sort duplicates #'string<) (rest duplicates))))
    (let* ((sorted (sort (copy-list definitions)
                         (lambda (a b)
                           (let ((ia (parse-identifier (first a)))
                                 (ib (parse-identifier (first b))))
                             (let ((ka (position (identifier-kind ia) *ledger-kinds*))
                                   (kb (position (identifier-kind ib) *ledger-kinds*)))
                               (or (< ka kb)
                                   (and (= ka kb)
                                        (or (string< (identifier-namespace ia)
                                                     (identifier-namespace ib))
                                            (and (string= (identifier-namespace ia)
                                                          (identifier-namespace ib))
                                                 (< (identifier-serial ia)
                                                    (identifier-serial ib)))))))))))
           (entries (mapcar (lambda (definition)
                              (destructuring-bind (id document where kind) definition
                                (declare (ignore where))
                                (if (eq kind :document)
                                    (make-ledger-entry :id id :kind kind
                                                       :path (document-path document)
                                                       :date today :by by)
                                    (make-ledger-entry :id id :kind kind
                                                       :host (document-id document)
                                                       :date today :by by))))
                            sorted)))
      (make-allocation
       :command :seed :entries entries
       :ledger-text (ledger-text-with-entries nil entries
                                              :namespaces (manifest-namespaces
                                                           (corpus-manifest corpus)))))))

;;; renumber

(defun strip-conflict-markers (text)
  "TEXT without Git conflict markers, keeping both sides of each conflict and
dropping the common-ancestor section of the diff3 style. Return the text and
true if there were markers."
  (let ((kept '()) (in-base nil) (found nil))
    (loop for line across (split-lines text)
          do (cond ((or (starts-with-p "<<<<<<<" line) (starts-with-p ">>>>>>>" line))
                    (setf found t in-base nil))
                   ((starts-with-p "|||||||" line) (setf found t in-base t))
                   ((and (string= line "=======") (or found in-base))
                    (setf in-base nil))
                   (in-base)
                   (t (push line kept))))
    (values (join-lines (nreverse kept)) found)))

(defun base-definition-ids (corpus base document)
  "The identifiers the revision BASE's version of DOCUMENT's file defines, or NIL
if the file does not exist there."
  (let ((text (git-file-at (corpus-root corpus) base (document-path document))))
    (when text
      (let ((old (parse-document text :path (document-path document))))
        (cons (document-id old) (mapcar #'record-id (document-records old)))))))

(defun plan-renumber (corpus &key base (today (today)))
  "Plan recovering from concurrent allocations (D25). Return an ALLOCATION."
  (require-ledger-namespaces corpus)
  (let* ((root (corpus-root corpus))
         (ledger-path (corpus-ledger-path corpus))
         (pathname (corpus-ledger-pathname corpus)))
    (unless base
      (refuse "no base revision was found (origin/HEAD, origin/main, or origin/master); ~
               pass --base with the branch you are merging into"))
    (unless (uiop:file-exists-p pathname)
      (refuse "there is no ledger (~a) to renumber" ledger-path))
    (multiple-value-bind (text had-markers) (strip-conflict-markers (read-text-file pathname))
      (multiple-value-bind (entries problems) (parse-ledger-text text :path ledger-path)
        (let ((errors (remove :warning problems :key #'finding-severity)))
          (when errors
            (refuse "the ledger has lines that are not entries, even with the conflict ~
                     markers removed: ~{line ~a~^, ~}" (mapcar #'finding-line errors))))
        (let* ((base-text (or (git-file-at root base ledger-path) ""))
               (base-entries (values (parse-ledger-text base-text)))
               (base-lines (mapcar #'ledger-entry-text base-entries))
               (base-ids (mapcar #'ledger-entry-id base-entries))
               (branch (remove-if (lambda (e) (member (ledger-entry-text e) base-lines
                                                      :test #'string=))
                                  entries))
               (by (allocator corpus))
               (warnings '())
               (mapping '())
               (taken (make-hash-table :test #'equal))
               (counters (make-hash-table :test #'equal)))
          (dolist (id base-ids) (setf (gethash id taken) t))
          (flet ((fresh (namespace kind)
                   (let ((counter (or (gethash namespace counters)
                                      (setf (gethash namespace counters)
                                            (make-counter corpus namespace base-entries
                                                          (mapcar #'ledger-entry-id
                                                                  entries))))))
                     (loop for id = (funcall counter kind)
                           unless (gethash id taken) return id))))
            ;; Entries this branch added, moved off numbers already taken.
            (let ((renumbered
                    (mapcar (lambda (entry)
                              (let* ((id (ledger-entry-id entry))
                                     (identifier (ledger-entry-identifier entry)))
                                (if (gethash id taken)
                                    (let ((new (fresh (identifier-namespace identifier)
                                                      (ledger-entry-kind entry))))
                                      (push (list id new (ledger-entry-kind entry)) mapping)
                                      (setf (gethash new taken) t)
                                      (let ((copy (copy-ledger-entry entry)))
                                        (setf (ledger-entry-id copy) new
                                              (ledger-entry-identifier copy)
                                              (parse-identifier new))
                                        copy))
                                    (progn (setf (gethash id taken) t) entry))))
                            branch))
                  (added '()))
              ;; Identifiers this branch defines with no entry of its own: an
              ;; entry dropped when the upstream ledger was taken. One that is
              ;; free keeps its number; one that another document also defines
              ;; now collides and moves. One defined once, and already in the
              ;; ledger, is a document this branch moved, and needs nothing.
              (let* ((branch-ids (mapcar #'ledger-entry-id branch))
                     (definitions (canonical-definitions corpus))
                     (counts (make-hash-table :test #'equal)))
                (dolist (d definitions) (incf (gethash (first d) counts 0)))
                (dolist (definition definitions)
                  (destructuring-bind (id document where kind) definition
                    (declare (ignore where))
                    (let ((namespace (identifier-namespace (parse-identifier id))))
                      (when (and (corpus-owned-namespace-p corpus namespace)
                                 (not (member id branch-ids :test #'string=))
                                 (not (member id (base-definition-ids corpus base document)
                                              :test #'string=))
                                 (or (not (gethash id taken))
                                     (> (gethash id counts) 1)))
                        (let* ((collides (gethash id taken))
                               (new (if collides (fresh namespace kind) id)))
                          (setf (gethash new taken) t)
                          (when collides (push (list id new kind) mapping))
                          (push (if (eq kind :document)
                                    (make-ledger-entry :id new :kind kind
                                                       :path (document-path document)
                                                       :date today :by by)
                                    (make-ledger-entry :id new :kind kind
                                                       :host (document-id document)
                                                       :date today :by by))
                                added)
                          (push (format nil "~a in ~a had no ledger entry; ~:[it keeps its ~
                                             number~;it becomes ~:*~a~], and any ~
                                             provisional alias it had is lost"
                                        id (document-path document)
                                        (and collides new))
                                warnings)))))))
              (setf mapping (nreverse mapping) added (nreverse added))
              ;; Hosts that moved.
              (let ((host-mapping (remove :document mapping :key #'third :test-not #'eq)))
                (dolist (entry (append renumbered added))
                  (let ((moved (find (ledger-entry-host entry) host-mapping
                                     :key #'first :test #'equal)))
                    (when moved (setf (ledger-entry-host entry) (second moved))))))
              (let* ((new-entries (append renumbered added))
                     (new-text (ledger-text-with-entries
                                (and (plusp (length base-text)) base-text) new-entries
                                :namespaces (manifest-namespaces (corpus-manifest corpus))))
                     (added-lines (make-hash-table :test #'equal)))
                (flet ((eligible (path line)
                         (multiple-value-bind (lines found) (gethash path added-lines)
                           (unless found
                             (multiple-value-bind (numbers all)
                                 (git-added-lines root base path)
                               (setf lines (if all :all numbers)
                                     (gethash path added-lines) lines)))
                           (or (eq lines :all) (member line lines)))))
                  (make-allocation
                   :command :renumber :mapping mapping :entries added
                   :ledger-text new-text
                   :rewrites (and mapping
                                  (plan-rewrites
                                   corpus
                                   (mapcar (lambda (m) (cons (first m) (second m))) mapping)
                                   :eligible #'eligible))
                   :warnings (append (and had-markers
                                          (list (format nil "the ledger's conflict markers were ~
                                                             removed, keeping both sides")))
                                     (nreverse warnings)
                                     (short-reference-warnings
                                      (short-references-to corpus (mapcar #'first mapping))))
                   :base base))))))))))

(defun format-short-references (shorts &key (limit 25))
  (with-output-to-string (out)
    (loop for (document short) in shorts
          for n from 0
          when (< n limit)
            do (format out "  ~a:~d:~d  ~a~@[  (probably ~a)~]~%" (document-path document)
                       (short-reference-line short) (short-reference-column short)
                       (short-reference-text short) (short-reference-suggestion short)))
    (when (> (length shorts) limit)
      (format out "  … and ~d more (compass check --rule ref/short-record lists them all)~%"
              (- (length shorts) limit)))))

(defun short-reference-warnings (shorts)
  (and shorts
       (list (format nil "~d short reference~:p to the records numbered here now point at ~
                          the wrong records; write ~:*~[~;it~:;them~] as full identifiers:~%~a"
                     (length shorts)
                     (string-right-trim '(#\Newline) (format-short-references shorts))))))

;;; Writing

(defun execute-allocation (corpus allocation)
  "Write ALLOCATION: the rewritten documents, the ledger, and, where one exists,
a regenerated index. Return the corpus loaded afresh."
  (let ((root (corpus-root corpus)))
    (dolist (rewrite (allocation-rewrites allocation))
      (write-text-file (or (rewrite-pathname rewrite) (root-file root (rewrite-path rewrite)))
                       (rewrite-new-text rewrite)))
    (when (allocation-ledger-text allocation)
      (write-text-file (corpus-ledger-pathname corpus) (allocation-ledger-text allocation)))
    (let ((fresh (load-corpus root :skip-unmarked t)))
      (when (uiop:file-exists-p (root-file root (index-relative-path fresh)))
        (write-index fresh))
      fresh)))

;;; The next provisional record of a document (D23)

(defun slug-from-path (path)
  (let* ((name (file-namestring path))
         (stem (subseq name 0 (or (search ".md" name :from-end t) (length name))))
         (topic (let ((dot (position #\. stem))) (if dot (subseq stem (1+ dot)) stem)))
         (slug (string-trim "-" (ppcre:regex-replace-all "[^a-z0-9]+"
                                                         (string-downcase
                                                          (ppcre:regex-replace-all
                                                           "([a-z0-9])([A-Z])" topic
                                                           "\\1-\\2"))
                                                         "-"))))
    (if (string= slug "") "document" slug)))

(defun next-provisional-record (corpus path kind)
  "The next provisional identifier of KIND for a record added to the document at
PATH: formed from its provisional identifier, or for a numbered document from
its alias in the ledger, or else from a slug no document uses (D23)."
  (let* ((document (document-at-path corpus path))
         (identifier (and document (document-identifier document)))
         (ledger (corpus-ledger corpus)))
    (unless identifier
      (refuse "~a is not a document of this corpus with a valid identifier" path))
    (let* ((namespace (identifier-namespace identifier))
           (prefix
             (cond ((identifier-provisional-p identifier) (identifier-string identifier))
                   ((first (ledger-aliases-of ledger (identifier-string identifier))))
                   (t (loop for n from 1
                            for slug = (if (= n 1) (slug-from-path path)
                                           (format nil "~a-~d" (slug-from-path path) n))
                            for candidate = (format nil "~a-DRAFT-~a" namespace slug)
                            unless (or (find-document corpus candidate)
                                       (ledger-alias-entry ledger candidate))
                              return candidate))))
           (highest 0))
      (flet ((consider (id)
               (let ((parsed (parse-identifier id)))
                 (when (and parsed (identifier-provisional-p parsed)
                            (eq (identifier-kind parsed) kind)
                            (equal (identifier-host parsed) prefix))
                   (setf highest (max highest (identifier-serial parsed)))))))
        (dolist (record (document-records document)) (consider (record-id record)))
        (when ledger
          (dolist (entry (ledger-entries ledger))
            (when (ledger-entry-draft entry) (consider (ledger-entry-draft entry))))))
      (format nil "~a-~a~d" prefix (register-kind-letter (find-register-kind kind))
              (1+ highest)))))

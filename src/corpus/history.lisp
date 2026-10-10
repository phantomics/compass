;;;; history.lisp — Front-matter fields derived from Git: authors, created, and updated
;;;;
;;;; Read-if: changing how authors or dates are derived, or what counts as derivable
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D27
;;;; Invariant: a value written in front-matter always wins; derived values are never written back
;;;; Invariant: checking derivability runs a fixed number of Git processes, not one per document
;;;; Tests: tests/test-code-refs.lisp

(in-package #:compass.corpus)

(defun repository-usable-p (corpus root)
  "True if Git runs and ROOT is in a Git work tree, asked once per load."
  (corpus-cached corpus (list :usable (uiop:native-namestring root))
                 (lambda () (and (git-available-p) (git-repository-p root) t))))

(defstruct (git-state)
  usable                                ; true if Git runs and the root is in a work tree
  reason                                ; :no-git or :not-a-repository when not usable
  identity                              ; the current user, through .mailmap, or NIL
  committed                             ; hash table of the paths in HEAD
  shallow)                              ; true in a shallow clone

(defun corpus-git-state (corpus)
  "What Git can say about the repository of CORPUS, asked once per load."
  (corpus-cached
   corpus :git-state
   (lambda ()
     (let ((root (corpus-root corpus)))
       (cond
         ((not (git-available-p)) (make-git-state :reason :no-git))
         ((not (repository-usable-p corpus root)) (make-git-state :reason :not-a-repository))
         (t (let ((committed (make-hash-table :test #'equal)))
              (dolist (path (git-committed-files root)) (setf (gethash path committed) t))
              (make-git-state :usable t :identity (git-identity root)
                              :committed committed :shallow (git-shallow-p root)))))))))

(defun document-committed-p (corpus document)
  "True if DOCUMENT's file is in the commit HEAD."
  (let ((state (corpus-git-state corpus)))
    (and (git-state-usable state)
         (gethash (document-path document) (git-state-committed state))
         t)))

(defun underivable-reason (corpus document)
  "Why the Git-derivable fields of DOCUMENT cannot be derived, as a phrase, or
NIL if they can be; and a second value, true if setting a Git user name would
make them derivable. Without Git, NIL; the caller checks for that."
  (let ((state (corpus-git-state corpus)))
    (cond ((eq (git-state-reason state) :not-a-repository)
           (format nil "~a is not in a Git work tree" (document-path document)))
          ((and (git-state-usable state)
                (not (document-committed-p corpus document))
                (null (git-state-identity state)))
           (values "the file has no commit yet, and Git has no user.name to credit" t))
          (t nil))))

(defstruct (derived-field)
  name                                  ; "authors", "created", or "updated"
  value                                 ; a list of names, or a YYYY-MM-DD date, or NIL
  source                                ; :front-matter, :git, :working-tree, or NIL
  (note nil))                           ; a caveat, such as a shallow clone

(defun front-matter-value (document name)
  (let ((node (document-field-node document name)))
    (if (string= name "authors")
        (node-identifiers node)
        (node-string node))))

(defun document-derived-fields (corpus document)
  "The authors, created, and updated of DOCUMENT, each as a DERIVED-FIELD: the
front-matter value if there is one, otherwise derived from Git (D27). A field
that cannot be derived has no value and no source."
  (corpus-cached
   corpus (list :derived (document-path document))
   (lambda ()
     (let* ((state (corpus-git-state corpus))
            (root (corpus-root corpus))
            (path (document-path document))
            (history (and (git-state-usable state) (git-log-follow root path)))
            (status (and (git-state-usable state) (git-file-status root path)))
            (pending (and (git-state-usable state)
                          (or (null history) (not (eq status :clean)))))
            (identity (git-state-identity state)))
       (flet ((field (name derived source &optional note)
                (let ((written (front-matter-value document name)))
                  (if written
                      (make-derived-field :name name :value written :source :front-matter)
                      (make-derived-field :name name :value derived
                                          :source (and derived source)
                                          :note (and derived note))))))
         (list
          (field "authors"
                 (let ((names (remove-duplicates (mapcar #'first history)
                                                 :test #'string= :from-end t)))
                   (if (and pending identity (not (member identity names :test #'string=)))
                       (append names (list identity))
                       names))
                 (if (and pending (null history)) :working-tree :git))
          (field "created"
                 (if history (second (first history)) (and pending (today)))
                 (if history :git :working-tree)
                 (and history (git-state-shallow state)
                      "possibly later than the first commit: this is a shallow clone"))
          (field "updated"
                 (if pending (today) (second (first (last history))))
                 (if pending :working-tree :git))))))))

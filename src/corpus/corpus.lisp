;;;; corpus.lisp — Discover, load, and index the documents of a repository
;;;;
;;;; Read-if: changing which files are documents, how the repository root is found, or identifier lookup
;;;; See: COMPASS-DRAFT-toolchain-D10, COMPASS-DRAFT-toolchain-D21
;;;; Invariant: discovery is deterministic: files are loaded in path order
;;;; Tests: tests/test-corpus.lisp

(in-package #:compass.corpus)

(defclass corpus ()
  ((root :initarg :root :reader corpus-root)
   (manifest :initarg :manifest :reader corpus-manifest)
   (documents :initform '() :accessor corpus-documents)
   (skipped :initform '() :accessor corpus-skipped
            :documentation "Paths of files without front-matter skipped by --skip-unmarked.")
   (load-findings :initform '() :accessor corpus-load-findings)
   (unverified :initform '() :accessor corpus-unverified
               :documentation "References into namespaces that are not loaded.")
   (namespaces :initform '() :accessor corpus-namespaces)
   (by-id :initform (make-hash-table :test #'equal) :reader corpus-by-id)
   (records-by-id :initform (make-hash-table :test #'equal) :reader corpus-records-by-id)
   (by-path :initform (make-hash-table :test #'equal) :reader corpus-by-path)
   (anchor-cache :initform (make-hash-table :test #'equal) :reader corpus-anchor-cache)))

(defun corpus-doc-directory (corpus)
  (manifest-doc-directory (corpus-manifest corpus)))

;;; The repository root

(defun parent-directory (directory)
  (let ((parent (uiop:pathname-parent-directory-pathname directory)))
    (and (not (uiop:pathname-equal parent directory)) parent)))

(defun find-repository-root (&optional (start (uiop:getcwd)))
  "The nearest directory at or above START containing compass.sexp, else the
nearest containing .git, else START itself."
  (let ((start (uiop:ensure-directory-pathname start)))
    (flet ((search-up (test)
             (loop for directory = start then (parent-directory directory)
                   while directory
                   when (funcall test directory) return directory)))
      (or (search-up (lambda (d) (uiop:file-exists-p
                                  (merge-pathnames +manifest-file-name+ d))))
          (search-up (lambda (d) (or (uiop:directory-exists-p (merge-pathnames ".git/" d))
                                     (uiop:file-exists-p (merge-pathnames ".git" d)))))
          start))))

;;; Discovery

(defun markdown-files-under (directory)
  "Every .md file beneath DIRECTORY, skipping hidden directories."
  (let ((files '()))
    (labels ((walk (dir)
               (dolist (file (uiop:directory-files dir "*.md"))
                 (push file files))
               (dolist (sub (uiop:subdirectories dir))
                 (let ((name (car (last (pathname-directory sub)))))
                   (unless (and (stringp name) (starts-with-p "." name))
                     (walk sub))))))
      (when (uiop:directory-exists-p directory) (walk directory)))
    files))

(defun opens-with-front-matter-p (pathname)
  (with-open-file (in pathname :external-format :utf-8 :if-does-not-exist nil)
    (and in
         (let ((line (ignore-errors (read-line in nil nil))))
           (and line
                (string= (string-right-trim '(#\Space #\Tab #\Return)
                                            (string-left-trim (list (code-char #xFEFF)) line))
                         "---"))))))

(defun discover-files (root doc-directory)
  "Return the candidate document files as (PATHNAME . RELATIVE-PATH) pairs, in
path order: .md files under DOC-DIRECTORY that are not non-documents, and .md
files at the root that open with front-matter."
  (let ((files '()))
    (dolist (file (markdown-files-under (root-file root doc-directory)))
      (unless (non-document-file-p (file-namestring file))
        (push (cons file (relative-path-string file root)) files)))
    (dolist (file (uiop:directory-files root "*.md"))
      (when (opens-with-front-matter-p file)
        (pushnew (cons file (relative-path-string file root)) files
                 :key #'cdr :test #'string=)))
    (sort files #'string< :key #'cdr)))

;;; Loading

(defun load-corpus (root &key manifest skip-unmarked)
  "Load the corpus of the repository at ROOT. MANIFEST, if given, replaces
compass.sexp. With SKIP-UNMARKED, files without front-matter are skipped and
listed instead of reported."
  (let* ((root (uiop:ensure-directory-pathname root))
         (manifest-file (merge-pathnames +manifest-file-name+ root))
         (findings '())
         (manifest (or manifest
                       (if (uiop:file-exists-p manifest-file)
                           (multiple-value-bind (m problems) (read-manifest manifest-file)
                             (setf findings (append findings problems))
                             m)
                           (default-manifest))))
         (corpus (make-instance 'corpus :root root :manifest manifest)))
    (dolist (entry (discover-files root (manifest-doc-directory manifest)))
      (destructuring-bind (pathname . path) entry
        (multiple-value-bind (document problem) (read-document pathname :path path)
          (cond
            ((null document) (push problem findings))
            ((not (document-has-front-matter-p document))
             (setf (gethash path (corpus-by-path corpus)) document)
             (if skip-unmarked
                 (push path (corpus-skipped corpus))
                 (push (make-finding
                        :rule "fm/present" :severity :error :path path :line 1
                        :message "no front-matter: a document in the document ~
                                  directory opens with a YAML block between --- lines ~
                                  (§7); use --skip-unmarked to skip files not yet migrated")
                       findings)))
            (t
             (setf (gethash path (corpus-by-path corpus)) document)
             (push document (corpus-documents corpus))
             (setf findings (append findings (document-load-findings document))))))))
    (setf (corpus-documents corpus) (nreverse (corpus-documents corpus))
          (corpus-skipped corpus) (nreverse (corpus-skipped corpus))
          (corpus-load-findings corpus) findings)
    (index-corpus corpus)
    corpus))

(defun index-corpus (corpus)
  (let ((namespaces (copy-list (manifest-namespaces (corpus-manifest corpus)))))
    (dolist (document (corpus-documents corpus))
      (let ((id (document-id document)))
        (when id
          (setf (gethash id (corpus-by-id corpus))
                (append (gethash id (corpus-by-id corpus)) (list document)))))
      (let ((ns (document-namespace document)))
        (when ns (pushnew ns namespaces :test #'string=)))
      (dolist (record (document-records document))
        (setf (gethash (record-id record) (corpus-records-by-id corpus))
              (append (gethash (record-id record) (corpus-records-by-id corpus))
                      (list record)))))
    (setf (corpus-namespaces corpus) (sort namespaces #'string<))))

;;; Lookup

(defun find-documents (corpus id)
  "Every loaded document declaring ID."
  (gethash id (corpus-by-id corpus)))

(defun find-document (corpus id)
  (first (find-documents corpus id)))

(defun find-records (corpus id)
  "Every record defined, by its heading, with identifier ID."
  (gethash id (corpus-records-by-id corpus)))

(defun find-record (corpus id)
  (first (find-records corpus id)))

(defun document-at-path (corpus path)
  "The document (or unmarked file) loaded from the repository-relative PATH."
  (gethash path (corpus-by-path corpus)))

(defun namespace-loaded-p (corpus namespace)
  (and (member namespace (corpus-namespaces corpus) :test #'string=) t))

(defun note-unverified (corpus path line reference)
  "Record a reference into a namespace that is not loaded."
  (push (list path line reference) (corpus-unverified corpus)))

(defun resolve (corpus reference)
  "Resolve \"ID\" or \"ID#anchor\". Return the document, record, or section,
and the document containing it; or NIL."
  (multiple-value-bind (id anchor) (split-reference reference)
    (let ((document (find-document corpus id))
          (record (find-record corpus id)))
      (cond
        ((and document anchor)
         (let ((section (find anchor (document-sections document)
                              :key #'section-anchor :test #'string=)))
           (and section (values section document))))
        (document (values document document))
        ((and record (null anchor)) (values record (record-document record)))
        (t nil)))))

(defun corpus-paths (corpus)
  "The repository-relative paths of every file the corpus considered: its
documents, files without front-matter, files that could not be read, and the
manifest."
  (let ((paths '()))
    (maphash (lambda (path document) (declare (ignore document)) (push path paths))
             (corpus-by-path corpus))
    (dolist (finding (corpus-load-findings corpus))
      (when (finding-path finding) (pushnew (finding-path finding) paths :test #'string=)))
    (when (uiop:file-exists-p (merge-pathnames +manifest-file-name+ (corpus-root corpus)))
      (pushnew +manifest-file-name+ paths :test #'string=))
    (sort paths #'string<)))

(defun corpus-empty-p (corpus)
  "True if the corpus found no candidate documents at all."
  (and (zerop (hash-table-count (corpus-by-path corpus)))
       (null (corpus-load-findings corpus))))

;;; Link destinations

(defparameter *url-scheme-scanner* (ppcre:create-scanner "^[A-Za-z][A-Za-z0-9+.-]*:"))

(defun path-directory (path)
  "The directory part of the repository-relative PATH, ending in /, or \"\"."
  (let ((slash (position #\/ path :from-end t)))
    (if slash (subseq path 0 (1+ slash)) "")))

(defun link-destination (document target)
  "Classify TARGET, the destination of a link in DOCUMENT. Return a keyword and,
for local targets, the repository-relative path and the fragment (or NIL):
:NONE for an empty target, :EXTERNAL for a URL, :OUTSIDE for a path that leaves
the repository, and :LOCAL otherwise. A bare #fragment targets DOCUMENT itself."
  (cond
    ((string= target "") (values :none nil nil))
    ((or (ppcre:scan *url-scheme-scanner* target) (starts-with-p "//" target))
     (values :external nil nil))
    (t
     (let* ((hash (position #\# target))
            (path-part (percent-decode (subseq target 0 hash)))
            (fragment (and hash (subseq target (1+ hash)))))
       (if (string= path-part "")
           (values :local (document-path document) fragment)
           (multiple-value-bind (path escapes)
               (normalize-relative-path (path-directory (document-path document)) path-part)
             (values (if escapes :outside :local) path fragment)))))))

(defun markdown-anchors (corpus path)
  "The heading anchors of the Markdown file at the repository-relative PATH,
whether or not it is a document; NIL if it cannot be read."
  (let ((document (document-at-path corpus path)))
    (if document
        (document-anchors document)
        (multiple-value-bind (anchors found) (gethash path (corpus-anchor-cache corpus))
          (if found
              anchors
              (setf (gethash path (corpus-anchor-cache corpus))
                    (let ((doc (read-document (root-file (corpus-root corpus) path)
                                              :path path)))
                      (and doc (document-anchors doc)))))))))

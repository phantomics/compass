;;;; document.lisp — The document model: YAML nodes, body structure, documents, and findings
;;;;
;;;; Read-if: adding a document part the parser records, or a field of a finding
;;;; See: COMPASS-DRAFT-toolchain-D7
;;;; Invariant: every node and body element records the line it came from, for findings

(in-package #:compass.model)

;;; YAML nodes produced by the front-matter parser. Every scalar is a string,
;;; or null; types come from the field schema (COMPASS-DRAFT-toolchain-D18).

(defstruct yaml-node
  (line nil)
  (column nil))

(defstruct (yaml-scalar (:include yaml-node))
  (value nil :type (or null string))
  (style :plain :type (member :plain :single :double :null)))

(defstruct (yaml-sequence (:include yaml-node))
  (items '() :type list))

(defstruct (yaml-entry)
  (key "" :type string)
  (line nil)
  (column nil)
  (value nil))

(defstruct (yaml-mapping (:include yaml-node))
  (entries '() :type list))

(defun yaml-null-p (node)
  (or (null node)
      (and (yaml-scalar-p node) (eq (yaml-scalar-style node) :null))))

(defun yaml-get-entry (mapping key)
  (and (yaml-mapping-p mapping)
       (find key (yaml-mapping-entries mapping) :key #'yaml-entry-key :test #'string=)))

(defun yaml-get (mapping key)
  "The value node for KEY in MAPPING, or NIL."
  (let ((entry (yaml-get-entry mapping key)))
    (and entry (yaml-entry-value entry))))

;;; Body structure

(defclass located ()
  ((line :initarg :line :initform nil :reader location-line)
   (column :initarg :column :initform nil :reader location-column)))

(defclass section (located)
  ((level :initarg :level :reader section-level)
   (text :initarg :text :reader section-text)
   (anchor :initarg :anchor :reader section-anchor)
   (parent :initarg :parent :initform nil :reader section-parent)
   (end-line :initarg :end-line :initform nil :accessor section-end-line)))

(defstruct (field-entry)
  (label "")
  (value "")
  (line nil))

(defclass register-record (located)
  ((id :initarg :id :reader record-id)
   (identifier :initarg :identifier :reader record-identifier)
   (title :initarg :title :reader record-title)
   (level :initarg :level :reader record-level)
   (short-form-p :initarg :short-form-p :initform nil :reader record-short-form-p)
   (separator :initarg :separator :initform "—" :reader record-separator)
   (fields :initarg :fields :initform '() :accessor record-fields)
   (end-line :initarg :end-line :initform nil :accessor record-end-line)
   (document :initarg :document :initform nil :accessor record-document)))

(defun record-kind (record)
  (identifier-kind (record-identifier record)))

(defun record-field-entry (record label)
  (find label (record-fields record) :key #'field-entry-label :test #'string-equal))

(defun record-field (record label)
  "The value of the bold-label field LABEL in RECORD, or NIL."
  (let ((entry (record-field-entry record label)))
    (and entry (field-entry-value entry))))

(defclass link (located)
  ((text :initarg :text :reader link-text)
   (target :initarg :target :reader link-target)
   (image-p :initarg :image-p :initform nil :reader link-image-p)))

(defclass table-block (located)
  ((caption :initarg :caption :initform nil :reader table-caption)
   (caption-line :initarg :caption-line :initform nil :reader table-caption-line)
   (header-cells :initarg :header-cells :reader table-header-cells)
   (end-line :initarg :end-line :reader table-end-line)))

(defclass fence (located)
  ((info :initarg :info :reader fence-info)
   (end-line :initarg :end-line :reader fence-end-line)
   (closed-p :initarg :closed-p :reader fence-closed-p)))

(defclass code-span (located)
  ((text :initarg :text :reader code-span-text)))

;;; Findings

(defstruct (finding (:constructor %make-finding))
  (rule "" :type string)
  (severity :error :type (member :error :warning))
  (path nil)
  (line nil)
  (column nil)
  (message "" :type string))

(defun make-finding (&key rule severity path line column message)
  (%make-finding :rule rule :severity severity :path path :line line
                 :column column :message message))

;;; Documents

(defclass document ()
  ((path :initarg :path :reader document-path
         :documentation "Path relative to the repository root, with / separators.")
   (pathname :initarg :pathname :reader document-pathname)
   (text :initarg :text :reader document-text)
   (lines :initarg :lines :reader document-lines)
   (has-front-matter-p :initarg :has-front-matter-p :initform nil
                       :reader document-has-front-matter-p)
   (front-matter :initarg :front-matter :initform nil :reader document-front-matter
                 :documentation "The parsed YAML-MAPPING, or NIL if absent or invalid.")
   (body-start-line :initarg :body-start-line :initform 1
                    :reader document-body-start-line)
   (sections :initarg :sections :initform '() :reader document-sections)
   (records :initarg :records :initform '() :reader document-records)
   (links :initarg :links :initform '() :reader document-links)
   (images :initarg :images :initform '() :reader document-images)
   (tables :initarg :tables :initform '() :reader document-tables)
   (fences :initarg :fences :initform '() :reader document-fences)
   (code-spans :initarg :code-spans :initform '() :reader document-code-spans)
   (load-findings :initarg :load-findings :initform '() :accessor document-load-findings)))

(defmethod print-object ((d document) stream)
  (print-unreadable-object (d stream :type t)
    (format stream "~a" (document-path d))))

(defun document-front-matter-valid-p (document)
  (and (document-front-matter document) t))

(defun document-field-node (document key)
  (yaml-get (document-front-matter document) key))

(defun document-field-string (document key)
  "The string value of the scalar field KEY, or NIL if absent, null, or not a scalar."
  (let ((node (document-field-node document key)))
    (and (yaml-scalar-p node) (not (yaml-null-p node)) (yaml-scalar-value node))))

(defun document-id (document) (document-field-string document "id"))
(defun document-genre (document) (document-field-string document "genre"))
(defun document-status (document) (document-field-string document "status"))
(defun document-title (document) (document-field-string document "title"))
(defun document-scope (document) (document-field-string document "scope"))
(defun document-component (document) (document-field-string document "component"))

(defun document-identifier (document)
  "The parsed identifier of DOCUMENT's id, if it is a valid document identifier."
  (let ((id (parse-identifier (document-id document))))
    (and id (identifier-document-p id) id)))

(defun document-namespace (document)
  (let ((id (document-identifier document)))
    (and id (identifier-namespace id))))

(defun document-anchors (document)
  (mapcar #'section-anchor (document-sections document)))

(defun document-record (document id)
  (find id (document-records document) :key #'record-id :test #'string=))

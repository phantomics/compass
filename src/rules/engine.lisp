;;;; engine.lisp — The rule registry, finding emission, and the check driver
;;;;
;;;; Read-if: adding a rule, changing severities, or changing how findings are collected
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain
;;;; Invariant: a MUST violation is an error and a SHOULD violation is a warning (§22)
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.rules)

(defclass rule ()
  ((name :initarg :name :reader rule-name)
   (severity :initarg :severity :reader rule-severity)
   (section :initarg :section :reader rule-section)
   (scope :initarg :scope :reader rule-scope
          :documentation ":document, :corpus, or :load (emitted while loading).")
   (front-matter :initarg :front-matter :reader rule-front-matter-p)
   (summary :initarg :summary :reader rule-summary)
   (function :initarg :function :reader rule-function)))

(defmethod print-object ((rule rule) stream)
  (print-unreadable-object (rule stream :type t)
    (format stream "~a" (rule-name rule))))

(defvar *rules* '() "Every rule, in definition order.")

(defun register-rule (rule)
  (let ((existing (position (rule-name rule) *rules* :key #'rule-name :test #'string=)))
    (if existing
        (setf (nth existing *rules*) rule)
        (setf *rules* (append *rules* (list rule))))
    rule))

(defmacro define-rule (name (&key (severity :error) section (scope :document)
                                (front-matter t) summary)
                       lambda-list &body body)
  "Define a rule. A :document rule's LAMBDA-LIST is (DOCUMENT CORPUS); a :corpus
rule's is (CORPUS). A :load rule has no body: its findings are produced while
the corpus loads. With FRONT-MATTER true, a :document rule runs only on
documents whose front-matter parsed."
  `(register-rule
    (make-instance 'rule :name ,name :severity ,severity :section ,section
                         :scope ,scope :front-matter ,front-matter
                         :summary ,(and summary
                                        (ppcre:regex-replace-all "~\\n[ \\t]*" summary ""))
                         :function ,(when lambda-list
                                      `(lambda ,lambda-list ,@body)))))

(defun find-rule (name)
  (find name *rules* :key #'rule-name :test #'string=))

(defun list-rules () (copy-list *rules*))

;;; Emission

(defvar *rule* nil "The rule being run.")
(defvar *findings* '() "Findings collected by the running check.")
(defvar *corpus* nil "The corpus being checked.")

(defun location-of (where)
  (typecase where
    (yaml-node (values (yaml-node-line where) (yaml-node-column where)))
    (yaml-entry (values (yaml-entry-line where) (yaml-entry-column where)))
    (located (values (location-line where) (location-column where)))
    (field-entry (values (field-entry-line where) nil))
    (integer (values where nil))
    (t (values 1 nil))))

(defun emit-severity (severity document where control &rest args)
  "Record a finding of SEVERITY for the running rule, at WHERE in DOCUMENT."
  (multiple-value-bind (line column) (location-of where)
    (push (make-finding :rule (rule-name *rule*) :severity severity
                        :path (if (typep document 'document) (document-path document) document)
                        :line line :column column
                        :message (apply #'format nil control args))
          *findings*)))

(defun emit (document where control &rest args)
  "Record a finding, with the running rule's severity, at WHERE in DOCUMENT."
  (apply #'emit-severity (rule-severity *rule*) document where control args))

(defun unverified (document where reference)
  "Note REFERENCE, into a namespace that is not loaded, as unverified."
  (note-unverified *corpus* (document-path document) (location-of where) reference))

;;; Running

(defun rule-selected-p (rule only exclude)
  "True if RULE is selected by ONLY (if any) and not removed by EXCLUDE. Each
pattern is a rule name, or a group such as \"fm\", \"fm/\", or \"fm/*\"."
  (flet ((matches (pattern)
           (let* ((name (rule-name rule))
                  (group (string-right-trim "*" pattern)))
             (or (string= pattern name)
                 (and (ends-with-p "/" group) (starts-with-p group name))
                 (and (not (find #\/ pattern))
                      (starts-with-p (concatenate 'string pattern "/") name))))))
    (and (or (null only) (some #'matches only))
         (notany #'matches exclude))))

(defun run-rules (corpus &key only exclude)
  "Run every selected rule over CORPUS. Return the findings."
  (setf (corpus-unverified corpus) '())
  (let ((*findings* '())
        (*corpus* corpus))
    (dolist (rule *rules*)
      (when (and (rule-function rule) (rule-selected-p rule only exclude))
        (let ((*rule* rule))
          (ecase (rule-scope rule)
            (:document
             (dolist (document (corpus-documents corpus))
               (when (or (not (rule-front-matter-p rule))
                         (document-front-matter document))
                 (funcall (rule-function rule) document corpus))))
            (:corpus (funcall (rule-function rule) corpus))))))
    (setf (corpus-unverified corpus) (nreverse (corpus-unverified corpus)))
    (nreverse *findings*)))

(defun finding< (a b)
  (let ((pa (or (finding-path a) "")) (pb (or (finding-path b) "")))
    (cond ((string< pa pb) t)
          ((string> pa pb) nil)
          ((/= (or (finding-line a) 0) (or (finding-line b) 0))
           (< (or (finding-line a) 0) (or (finding-line b) 0)))
          ((/= (or (finding-column a) 0) (or (finding-column b) 0))
           (< (or (finding-column a) 0) (or (finding-column b) 0)))
          (t (string< (finding-rule a) (finding-rule b))))))

(defun check-corpus (corpus &key only exclude paths)
  "The load findings and rule findings for CORPUS, sorted. ONLY and EXCLUDE
select rules; PATHS, if given, limits findings to those repository-relative
paths, where a path ending in / stands for every file beneath it."
  (let* ((load (remove-if-not (lambda (f)
                                (let ((rule (find-rule (finding-rule f))))
                                  (or (null rule) (rule-selected-p rule only exclude))))
                              (corpus-load-findings corpus)))
         (findings (append load (run-rules corpus :only only :exclude exclude))))
    (when paths
      (setf findings
            (remove-if-not (lambda (f)
                             (let ((path (finding-path f)))
                               (and path
                                    (some (lambda (p)
                                            (or (string= p path)
                                                (and (ends-with-p "/" p)
                                                     (starts-with-p p path))))
                                          paths))))
                           findings)))
    (stable-sort (copy-list findings) #'finding<)))

;;; Rules whose findings are produced while loading

(define-rule "file/read" (:severity :error :scope :load :section "§22"
                          :summary "Every document can be read as UTF-8 text")
  ())

(define-rule "manifest/valid" (:severity :error :scope :load :section "§13"
                               :summary "compass.sexp is a well-formed project manifest")
  ())

(define-rule "fm/syntax" (:severity :error :scope :load :section "§7"
                          :summary "Front-matter is within the YAML subset the toolchain reads")
  ())

(define-rule "fm/present" (:severity :error :scope :load :section "§7"
                           :summary "Every file in the document directory opens with front-matter")
  ())

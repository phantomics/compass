;;;; fields.lisp — Typed reading of front-matter fields against the field schema
;;;;
;;;; Read-if: changing the type of a front-matter field, or how a value is checked
;;;; See: COMPASS-DRAFT-toolchain-D18
;;;; Invariant: types come only from the schema; the parser never converts scalars
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.model)

(defun node-string (node)
  "The string of a non-null scalar NODE, or NIL."
  (and (yaml-scalar-p node) (not (yaml-null-p node)) (yaml-scalar-value node)))

(defun node-identifiers (node)
  "The scalar strings of NODE, which is a scalar or a sequence of scalars."
  (cond ((yaml-null-p node) '())
        ((yaml-scalar-p node) (list (yaml-scalar-value node)))
        ((yaml-sequence-p node)
         (loop for item in (yaml-sequence-items node)
               for s = (node-string item)
               when s collect s))
        (t '())))

(defun describe-node (node)
  (cond ((yaml-mapping-p node) "a mapping")
        ((yaml-sequence-p node) "a list")
        ((yaml-null-p node) "null")
        (t "a single value")))

(defun convert-field (spec node)
  "Read NODE as the field described by SPEC. Return the value, and a list of
problems, each (NODE SEVERITY MESSAGE). A null NODE is absent: (values NIL NIL)."
  (let ((problems '())
        (name (field-spec-name spec)))
    (labels ((problem (where message &rest args)
               (push (list where :error (apply #'format nil message args)) problems))
             (warn-about (where message &rest args)
               (push (list where :warning (apply #'format nil message args)) problems))
             (scalar (node what)
               (if (and (yaml-scalar-p node) (not (yaml-null-p node)))
                   (yaml-scalar-value node)
                   (progn (problem node "`~a` must be ~a, not ~a" name what
                                   (describe-node node))
                          nil)))
             (document-id (node)
               (let ((s (scalar node "an identifier")))
                 (when s
                   (let ((id (parse-identifier s)))
                     (cond ((null id)
                            (problem node "`~a` value ~s is not a Compass identifier"
                                     name s))
                           ((identifier-register-p id)
                            (problem node "`~a` names documents; ~a is a record identifier"
                                     name s))
                           (t s))))))
             (list-of (node fn what)
               (cond ((yaml-sequence-p node)
                      (loop for item in (yaml-sequence-items node)
                            for value = (funcall fn item)
                            when value collect value))
                     (t (problem node "`~a` must be a list of ~a, not ~a" name what
                                 (describe-node node))
                        nil))))
      (values
       (unless (yaml-null-p node)
         (ecase (field-spec-type spec)
           ((:string :vocabulary :language)
            (scalar node "a single value"))
           (:line
            (let ((s (scalar node "a single line of text")))
              (cond ((null s) nil)
                    ((blank-string-p s) (problem node "`~a` must not be empty" name) nil)
                    ((find #\Newline s) (problem node "`~a` must be a single line" name) s)
                    (t s))))
           (:identifier
            (if (string= name "id")
                (scalar node "an identifier")
                (document-id node)))
           (:date
            (let ((s (scalar node "a date")))
              (when s
                (if (valid-date-string-p s)
                    s
                    (problem node "`~a` value ~s is not a YYYY-MM-DD calendar date"
                             name s)))))
           (:string-list
            (list-of node (lambda (item) (scalar item "a name")) "names"))
           (:identifiers
            (list-of node #'document-id "identifiers"))
           (:identifier-or-list
            (if (yaml-sequence-p node)
                (list-of node #'document-id "identifiers")
                (document-id node)))
           (:provenance
            (if (not (yaml-mapping-p node))
                (progn (problem node "`provenance` must be a mapping with `assistant:`, not ~a"
                                (describe-node node))
                       nil)
                (let ((assistant (yaml-get-entry node "assistant")))
                  (if (or (null assistant) (yaml-null-p (yaml-entry-value assistant)))
                      (problem node "`provenance` must name its `assistant:`")
                      (scalar (yaml-entry-value assistant) "a single value"))
                  (let ((session (yaml-get node "session")))
                    (unless (yaml-null-p session) (scalar session "a single value")))
                  (dolist (entry (yaml-mapping-entries node))
                    (unless (member (yaml-entry-key entry) '("assistant" "session")
                                    :test #'string=)
                      (warn-about entry "`provenance` has an unrecognised key `~a`"
                                  (yaml-entry-key entry))))
                  node)))
           (:cites
            (list-of node
                     (lambda (item)
                       (if (yaml-mapping-p item)
                           item
                           (problem item "each `cites` entry must be a mapping with ~
                                          `title`, `locator`, and `external: true`")))
                     "mappings"))
           (:registers
            (let ((kind (find-register-kind (field-spec-register-kind spec))))
              (list-of node
                       (lambda (item)
                         (let ((s (scalar item "an identifier")))
                           (when s
                             (let ((id (parse-identifier s)))
                               (cond ((null id)
                                      (problem item "`~a` value ~s is not a Compass identifier"
                                               name s))
                                     ((not (eq (identifier-kind id)
                                               (register-kind-keyword kind)))
                                      (problem item "`~a` lists ~a records (<NS>-~a<n>); ~a is not one"
                                               name (string-downcase
                                                     (register-kind-label kind))
                                               (register-kind-letter kind) s))
                                     (t s))))))
                       "record identifiers")))))
       (nreverse problems)))))

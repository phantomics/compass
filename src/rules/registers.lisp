;;;; registers.lisp — Rules for decision, open-question, and memo records
;;;;
;;;; Read-if: changing how records are mirrored, numbered, or given a status
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D12, COMPASS-DRAFT-toolchain-D16
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.rules)

(defun listed-records (document)
  "Every record identifier listed in DOCUMENT's register fields, with its node,
as (ID NODE KIND)."
  (loop for kind in (register-kinds)
        for node = (document-field-node document (register-kind-field kind))
        when (yaml-sequence-p node)
          append (loop for item in (yaml-sequence-items node)
                       for id = (node-string item)
                       when id collect (list id item kind))))

(define-rule "register/mirrored" (:severity :error :section "§8"
                                  :summary "Records defined in the body and listed in ~
                                            front-matter agree")
    (document corpus)
  (let ((listed (listed-records document)))
    (dolist (record (document-records document))
      (let ((kind (find-register-kind (record-kind record))))
        (unless (find (record-id record) listed :key #'first :test #'string=)
          (emit document record "record ~a is defined here but not listed in `~a:`"
                (record-id record) (register-kind-field kind)))))
    (dolist (item listed)
      (destructuring-bind (id node kind) item
        (declare (ignore kind))
        (let ((parsed (parse-identifier id)))
          (when (and parsed (not (document-record document id)))
            (cond
              ((find-record corpus id))   ; amends a record defined elsewhere
              ((not (namespace-loaded-p corpus (identifier-namespace parsed)))
               (unverified document node id))
              (t (emit document node "~a is listed here but defined nowhere in the corpus; ~
                                      define it with a heading \"### ~a — <title>\""
                       id id)))))))))

(define-rule "register/unique" (:severity :error :scope :corpus :section "§8, §13"
                                :summary "No record is defined in more than one place")
    (corpus)
  (dolist (document (corpus-documents corpus))
    (dolist (record (document-records document))
      (let ((others (remove record (find-records corpus (record-id record)))))
        (when others
          (emit document record "record ~a is also defined at ~{~a~^, ~}" (record-id record)
                (mapcar (lambda (r) (format nil "~a:~a" (document-path (record-document r))
                                            (location-line r)))
                        others)))))))

(define-rule "register/status" (:severity :error :section "§8"
                                :front-matter nil
                                :summary "Every decision and memo record has a controlled ~
                                          `**Status:**`")
    (document corpus)
  (declare (ignore corpus))
  (dolist (record (document-records document))
    (let* ((kind (find-register-kind (record-kind record)))
           (family (register-kind-family kind)))
      (when family
        (let ((entry (record-field-entry record "Status")))
          (cond
            ((null entry)
             (emit document record "~a record ~a has no `**Status:**` line"
                   (register-kind-label kind) (record-id record)))
            ((not (find-status-in-family family (field-entry-value entry)))
             (emit document entry "~s is not a status of a ~a record; use one of ~a"
                   (field-entry-value entry)
                   (string-downcase (register-kind-label kind))
                   (quoted-list (mapcar #'term-name (statuses-in-family family)))))))))))

(define-rule "register/heading-form" (:severity :warning :section "§8"
                                      :front-matter nil
                                      :summary "Record headings are H3, use the full ~
                                                identifier, and an em dash")
    (document corpus)
  (declare (ignore corpus))
  (dolist (record (document-records document))
    (cond
      ((record-short-form-p record)
       (emit document record "record heading uses the short form; write the full ~
                              identifier: \"### ~a — ~a\"" (record-id record)
             (record-title record)))
      ((/= (record-level record) 3)
       (emit document record "record ~a has a level-~a heading; record headings are level 3 ~
                              (###)" (record-id record) (record-level record)))
      ((string/= (record-separator record) "—")
       (emit document record "record ~a separates its identifier and title with ~s; use an ~
                              em dash (—)" (record-id record) (record-separator record))))))

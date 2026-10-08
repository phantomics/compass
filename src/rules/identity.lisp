;;;; identity.lisp — Rules for document identifiers and their uniqueness
;;;;
;;;; Read-if: changing the identifier rules
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D2
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.rules)

(define-rule "id/format" (:severity :error :section "§5, §13"
                          :summary "Identifiers are well formed, and records belong to ~
                                    their host")
    (document corpus)
  (declare (ignore corpus))
  (let* ((entry (field-entry document "id"))
         (id (and entry (node-string (yaml-entry-value entry)))))
    (when id
      (let ((problem (diagnose-identifier id)))
        (when problem
          (emit document (yaml-entry-value entry) "invalid id ~s: ~a" id problem))))
    (let ((host (document-identifier document)))
      (when host
        (dolist (record (document-records document))
          (let ((rid (record-identifier record)))
            (cond
              ((string/= (identifier-namespace rid) (identifier-namespace host))
               (emit document record "record ~a is in the ~a namespace, but its host ~
                                      document ~a is in ~a"
                     (record-id record) (identifier-namespace rid) (identifier-string host)
                     (identifier-namespace host)))
              ((and (identifier-provisional-p rid)
                    (string/= (identifier-host rid) (identifier-string host)))
               (emit document record "provisional record ~a belongs to ~a, but is defined ~
                                      in ~a; a provisional record identifier is formed ~
                                      from its host's"
                     (record-id record) (identifier-host rid) (identifier-string host))))))))))

(define-rule "id/unique" (:severity :error :scope :corpus :section "§5, §13"
                          :summary "No two documents declare the same id")
    (corpus)
  (dolist (document (corpus-documents corpus))
    (let* ((id (document-id document))
           (others (and id (remove document (find-documents corpus id)))))
      (when others
        (emit document (field-entry document "id")
              "id ~a is also declared by ~{~a~^, ~}" id (mapcar #'document-path others))))))

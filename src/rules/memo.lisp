;;;; memo.lisp — Rules for Memo documents and their M-records
;;;;
;;;; Read-if: changing the memo rules, M-record fields, or the basis test
;;;; See: COMPASS-0001, COMPASS-DRAFT-agent-workflow-D2, COMPASS-DRAFT-agent-workflow-D3
;;;; See: COMPASS-DRAFT-toolchain-D28
;;;; Invariant: memo/basis checks that a pinned revision exists only where Git can tell
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.rules)

(defun memo-records (document)
  (remove :memo (document-records document) :key #'record-kind :test-not #'eq))

(define-rule "memo/host" (:severity :error :section "§4, §8"
                          :summary "Memo records appear only in Memo documents, which ~
                                    hold only memo records")
    (document corpus)
  (declare (ignore corpus))
  (let ((genre (document-genre document)))
    (when (find-genre genre)
      (if (string= genre "Memo")
          (dolist (record (document-records document))
            (unless (eq (record-kind record) :memo)
              (emit document record "a Memo document holds only memo records; ~a is ~a ~
                                     record" (record-id record)
                    (string-downcase (register-kind-label
                                      (find-register-kind (record-kind record)))))))
          (progn
            (dolist (record (memo-records document))
              (emit document record "memo record ~a is in a ~a document; memo records ~
                                     appear only in Memo documents" (record-id record) genre))
            (let ((entry (field-entry document "memos")))
              (when (and entry (not (yaml-null-p (yaml-entry-value entry))))
                (emit document entry "`memos:` appears only in Memo documents"))))))))

(define-rule "memo/fields" (:severity :error :section "§6, §8" :front-matter nil
                            :summary "Each memo record has `**Read-if:**` and ~
                                      `**Basis:**`, and `**Superseded-by:**` exactly when ~
                                      it is Superseded")
    (document corpus)
  (declare (ignore corpus))
  (dolist (record (memo-records document))
    (dolist (label '("Read-if" "Basis"))
      (let ((value (record-field record label)))
        (when (or (null value) (blank-string-p value))
          (emit document record "memo record ~a has no `**~a:**` line" (record-id record)
                label))))
    (let ((read-if (record-field-entry record "Read-if")))
      (when (and read-if (> (length (field-entry-value read-if)) 160))
        (emit-severity :warning document read-if
                       "the `**Read-if:**` of ~a is ~a characters; keep it within 160"
                       (record-id record) (length (field-entry-value read-if)))))
    (let ((status (record-field record "Status"))
          (successor (record-field-entry record "Superseded-by")))
      (cond ((and (equal status "Superseded") (null successor))
             (emit document record "memo record ~a is Superseded but has no ~
                                    `**Superseded-by:**` line" (record-id record)))
            ((and successor (not (equal status "Superseded")))
             (emit document successor "`**Superseded-by:**` appears only with status ~
                                       Superseded"))))
    (let ((recorded (record-field-entry record "Recorded")))
      (when (and recorded (not (valid-date-string-p (field-entry-value recorded))))
        (emit document recorded "`**Recorded:**` value ~s is not a YYYY-MM-DD calendar date"
              (field-entry-value recorded))))))

(defun cite-titles (document)
  (let ((cites (document-field-node document "cites")))
    (and (yaml-sequence-p cites)
         (loop for item in (yaml-sequence-items cites)
               for title = (and (yaml-mapping-p item) (node-string (yaml-get item "title")))
               when (and title (plusp (length title))) collect title))))

(defun looks-like-code-path-p (string)
  (and (not (find #\Space string))
       (or (find #\/ string) (ppcre:scan "\\.[A-Za-z0-9]+(?::|#L|$)" string))))

(define-rule "memo/basis" (:severity :error :section "§4"
                           :summary "Each memo's basis names a commit-pinned code reference, ~
                                     a resolving identifier, or a `cites:` title")
    (document corpus)
  (dolist (record (memo-records document))
    (let* ((entry (record-field-entry record "Basis"))
           (basis (and entry (field-entry-value entry))))
      (when (and basis (not (blank-string-p basis)))
        (let* ((spans (mapcar (lambda (region)
                                (string-trim "`" (subseq basis (car region) (cdr region))))
                              (find-code-spans basis)))
               (pinned (some #'parse-code-reference spans))
               (unpinned (find-if #'looks-like-code-path-p spans))
               (identifiers (find-identifiers-in-text basis))
               (resolved nil))
          (unless pinned
            (dolist (id identifiers)
              (let ((parsed (parse-identifier id)))
                (cond ((or (find-document corpus id) (find-record corpus id))
                       (setf resolved t))
                      ((not (namespace-loaded-p corpus (identifier-namespace parsed)))
                       (unverified document entry id)
                       (setf resolved t))))))
          ;; A pinned reference must name a revision that exists, where Git can tell.
          (dolist (span spans)
            (let ((reference (parse-code-reference span)))
              (when reference
                (let ((status (revision-status corpus (code-reference-namespace reference)
                                               (code-reference-revision reference))))
                  (when (member status '(:missing :ambiguous))
                    (emit document entry "the basis of ~a cites `~a`, whose revision ~a ~
                                          ~:[names no commit or tag~;is an abbreviation of ~
                                          more than one object~]"
                          (record-id record) span (code-reference-revision reference)
                          (eq status :ambiguous)))))))
          (unless (or pinned resolved
                      (some (lambda (title) (search title basis)) (cite-titles document)))
            (if (and unpinned (not (parse-code-reference unpinned)))
                (emit document entry "the basis of ~a cites `~a`, which is not pinned to a ~
                                      revision; write `path:symbol@revision`"
                      (record-id record) unpinned)
                (emit document entry "the basis of ~a names no commit-pinned code reference ~
                                      (`path:symbol@revision`), no identifier in the corpus, ~
                                      and no `cites:` title" (record-id record)))))))))

;;;; code.lisp — Rules for code references, pinned to a revision and naming what exists there, and for the original a migrated document names
;;;;
;;;; Read-if: changing how code references or `provenance.migrated-from` are reported
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D28, COMPASS-DRAFT-migration-D3
;;;; Invariant: without Git, or for a namespace that is not loaded, nothing is reported
;;;; Tests: tests/test-code-refs.lisp

(in-package #:compass.rules)

(defun pinning-severity (document)
  "Pinning is mandatory in a Log or Plan, and recommended elsewhere (§9)."
  (if (member (document-genre document) '("Log" "Plan") :test #'equal) :error :warning))

(define-rule "ref/code-pinned" (:severity :error :section "§9" :front-matter nil
                                :summary "Code references that name a location are pinned ~
                                          to a revision (an error in a Log or Plan, a ~
                                          warning elsewhere)")
    (document corpus)
  (let ((severity (pinning-severity document)))
    (dolist (mention (document-code-mentions corpus document))
      (let ((line (code-mention-line mention)))
        (cond
          ((null (code-mention-revision mention))
           (emit-severity severity document (code-mention-span mention)
                          "`~a` names a place in code but no revision; pin it to a ~
                           commit, as `~a@<commit>`~@[, and write the line as `#L~a`~]"
                          (code-mention-text mention)
                          (if line
                              (format nil "~@[~a:~]~a#L~a" (code-mention-namespace mention)
                                      (code-mention-path mention) line)
                              (code-mention-text mention))
                          line))
          (line
           (emit-severity severity document (code-mention-span mention)
                          "`~a` gives a line as `:~a`; write it `#L~a`"
                          (code-mention-text mention) line line)))))))

(define-rule "ref/code-exists" (:severity :error :section "§9" :front-matter nil
                                :summary "A pinned code reference names a revision and path ~
                                          that exist (errors), and a symbol or lines found ~
                                          there (warnings)")
    (document corpus)
  (let ((results (resolve-code-mentions corpus)))
    (dolist (mention (document-code-mentions corpus document))
      (let ((result (gethash mention results))
            (span (code-mention-span mention))
            (text (code-mention-text mention)))
        (when result
          (ecase (first result)
            (:ok)
            (:unverified (unverified document span text))
            (:no-git
             (note corpus "ref/code-exists did not run~:[~; for ~:*~a~]: ~:[~a is not in a Git ~
                           repository~;Git was not found~*~]"
                   (code-mention-namespace mention) (not (git-available-p))
                   (uiop:native-namestring (second result))))
            ((:missing-revision :ambiguous-revision)
             ;; In a memo's basis, memo/basis reports the revision.
             (unless (code-mention-basis-p mention)
               (emit document span
                     (if (eq (first result) :ambiguous-revision)
                         "the revision ~a of `~a` is an abbreviation of more than one ~
                          object; write more of it"
                         "the revision ~a of `~a` names no commit or tag~:[~; in the ~:*~a ~
                          repository~]")
                     (code-mention-revision mention) text (code-mention-namespace mention))))
            (:missing-path
             (emit document span "~a does not exist at ~a, so `~a` names nothing"
                   (code-mention-path mention) (code-mention-revision mention) text))
            (:directory
             (emit-severity :warning document span
                            "~a is a directory at ~a, so the place `~a` names cannot be found"
                            (code-mention-path mention) (code-mention-revision mention) text))
            (:beyond-end
             (emit-severity :warning document span
                            "~a has ~d line~:p at ~a, fewer than `~a` names"
                            (code-mention-path mention) (second result)
                            (code-mention-revision mention) text))
            (:missing-symbol
             (emit-severity :warning document span
                            "~a defines no ~a at ~a, as far as this check can tell; check ~
                             `~a`"
                            (code-mention-path mention) (code-mention-symbol mention)
                            (code-mention-revision mention) text))))))))

(define-rule "ref/migrated-from" (:severity :error :section "§7, §9"
                                  :summary "`provenance.migrated-from` names a commit that ~
                                            exists, and a file that existed at it")
    (document corpus)
  (multiple-value-bind (entry path revision) (document-migrated-from document)
    (when (and entry path)
      (let ((result (gethash document (resolve-migrated-from corpus)))
            (where (yaml-entry-value entry)))
        (when result
          (ecase (first result)
            (:ok)
            (:unverified (unverified document where (format nil "~a@~a" path revision)))
            (:no-git
             (note corpus "ref/migrated-from did not run: ~:[~a is not in a Git ~
                           repository~;Git was not found~*~]"
                   (not (git-available-p)) (uiop:native-namestring (second result))))
            (:ambiguous-revision
             (emit document where "the revision ~a of `provenance.migrated-from` is an ~
                                   abbreviation of more than one object; write more of it"
                   revision))
            (:missing-revision
             (emit document where "`provenance.migrated-from` names ~a, which is no commit ~
                                   here; if the history was rewritten, pin the original's ~
                                   path to the commit that holds it now"
                   revision))
            (:missing-path
             (emit document where "~a does not exist at ~a, so `provenance.migrated-from` ~
                                   names no original"
                   path revision))
            (:directory
             (emit document where "~a is a directory at ~a; `provenance.migrated-from` ~
                                   names the original document, which is a file"
                   path revision))))))))

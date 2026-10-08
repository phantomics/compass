;;;; test-rules.lisp — Each v0.1 rule fires on a violation and stays quiet on conforming input

(in-package #:compass.tests)

(def-suite rules :in compass)
(in-suite rules)

(defun check-one (text &key rules (path "doc/Plan.Test.md") extra-files)
  "Findings for a repository holding TEXT at PATH, plus EXTRA-FILES."
  (check-files (cons (list path text) extra-files) :rules rules))

(test conforming-document-is-clean
  (let ((findings (check-one (doc))))
    (is (null findings) (describe-findings findings))))

(test fm-present-and-syntax
  (let ((findings (check-files (list (list "doc/Plan.A.md" (lines "# No front-matter"))))))
    (is (has-finding-p findings "fm/present" :path "doc/Plan.A.md")))
  (multiple-value-bind (findings corpus)
      (check-files (list (list "doc/Plan.A.md" (lines "# No front-matter")))
                   :skip-unmarked t)
    (is (null findings))
    (is (equal '("doc/Plan.A.md") (corpus-skipped corpus))))
  (let ((findings (check-one (doc :extra '("status2: Superseded-by: X-0002")))))
    (is (has-finding-p findings "fm/syntax" :line 10))))

(test fm-required
  (let ((findings (check-one (doc :title nil :language nil) :rules '("fm/required"))))
    (is (= 2 (length findings)) (describe-findings findings)))
  (let ((findings (check-one (doc :authors nil) :rules '("fm/required"))))
    (is (null findings) "authors is Git-derivable, checked in v0.2")))

(test fm-types
  (flet ((types (&rest extra)
           (check-one (doc :extra extra) :rules '("fm/types"))))
    (is (has-finding-p (types "created: 10.07.2026") "fm/types"))
    (is (has-finding-p (types "created: 2026-02-30") "fm/types"))
    (is (null (types "created: 2026-10-07")))
    (is (has-finding-p (types "reviewers: Ada") "fm/types"))
    (is (has-finding-p (types "relates-to: COMPASS-0001") "fm/types"))
    (is (has-finding-p (types "relates-to:" "  - COMPASS-D1") "fm/types"))
    (is (has-finding-p (types "decisions:" "  - TEST-O1") "fm/types"))
    (is (has-finding-p (types "provenance: opencode") "fm/types"))
    (is (has-finding-p (types "provenance:" "  session: x") "fm/types"))
    (is (has-finding-p (types "provenance:" "  assistant: x" "  model: y") "fm/types"
                       :severity :warning))
    (is (has-finding-p (types "glossary: Glossary.Terms") "fm/types" :severity :warning)))
  (is (has-finding-p (check-one (doc :title "\"\"") :rules '("fm/types")) "fm/types")))

(test fm-language
  (is (has-finding-p (check-one (doc :language "en_US") :rules '("fm/language"))
                     "fm/language"))
  (is (null (check-one (doc :language "no") :rules '("fm/language")))
      "no is Norwegian, not false"))

(test fm-unknown-key
  (let ((findings (check-one (doc :extra '("relates_to: []")) :rules '("fm/unknown-key"))))
    (is (has-finding-p findings "fm/unknown-key" :severity :warning))
    (is (search "relates-to" (finding-message (first findings))))))

(test vocabularies
  (is (search "Architecture"
              (finding-message
               (first (check-one (doc :genre "Arch") :rules '("vocab/genre"))))))
  (is (has-finding-p (check-one (doc :scope "team") :rules '("vocab/scope")) "vocab/scope"))
  (is (has-finding-p (check-one (doc :status "Current") :rules '("vocab/status"))
                     "vocab/status"))
  (is (null (check-one (doc :genre "Ref" :status "Current") :rules '("vocab/status"))))
  (is (has-finding-p (check-one (doc :status "\"Superseded-by: TEST-0002\"")
                                :rules '("vocab/status"))
                     "vocab/status" :severity :warning))
  (is (has-finding-p (check-one (doc :extra '("subtype: howto")) :rules '("vocab/subtype"))
                     "vocab/subtype" :severity :error))
  (is (has-finding-p (check-one (doc :genre "Eval") :rules '("vocab/subtype"))
                     "vocab/subtype" :severity :warning))
  (is (null (check-one (doc :genre "Eval" :extra '("subtype: comparison"))
                       :rules '("vocab/subtype")))))

(test vocab-pending
  (is (has-finding-p (check-one (doc :status "Superseded"
                                     :extra '("superseded-by: TEST-0002"))
                                :rules '("vocab/pending"))
                     "vocab/pending"))
  (is (has-finding-p (check-one (doc :genre "Glossary" :status "Current")
                                :rules '("vocab/pending"))
                     "vocab/pending"))
  (is (has-finding-p (check-one (doc :extra '("read-if: changing things"))
                                :rules '("vocab/pending"))
                     "vocab/pending"))
  (is (null (check-one (doc :genre "Memo" :status "Current") :rules '("vocab/pending")))
      "the Memo genre is accepted"))

(test superseded-agrees
  (flet ((agrees (status &rest extra)
           (check-one (doc :status status :extra extra) :rules '("status/superseded-agrees"))))
    (is (has-finding-p (agrees "Superseded") "status/superseded-agrees"))
    (is (has-finding-p (agrees "Accepted" "superseded-by: TEST-0002")
                       "status/superseded-agrees"))
    (is (null (agrees "Superseded" "superseded-by: TEST-0002")))
    (is (has-finding-p (agrees "\"Superseded-by: TEST-0003\"" "superseded-by: TEST-0002")
                       "status/superseded-agrees"))))

(test cite-well-formed
  (flet ((cites (&rest extra)
           (check-one (doc :extra (cons "cites:" extra)) :rules '("cite/well-formed"))))
    (is (null (cites "  - title: T" "    locator: L" "    external: true")))
    (is (has-finding-p (cites "  - title: T" "    locator: L") "cite/well-formed"))
    (is (has-finding-p (cites "  - title: T" "    locator: L" "    external: false")
                       "cite/well-formed"))
    (is (has-finding-p (cites "  - title: T" "    external: true") "cite/well-formed"))
    (is (has-finding-p (cites "  - title: T" "    locator: L" "    external: true"
                              "    url: x")
                       "cite/well-formed" :severity :warning))))

(test id-format
  (is (has-finding-p (check-one (doc :id "TEST-1") :rules '("id/format")) "id/format"))
  (is (has-finding-p (check-one (doc :id "TEST-D1") :rules '("id/format")) "id/format"))
  (is (null (check-one (doc :id "TEST-DRAFT-a-b") :rules '("id/format"))))
  (let ((text (doc :id "TEST-DRAFT-host"
                   :extra '("decisions:" "  - TEST-DRAFT-other-D1")
                   :body (lines "# T" "### TEST-DRAFT-other-D1 — Wrong host"
                                "**Status:** Accepted"))))
    (is (has-finding-p (check-one text :rules '("id/format")) "id/format")))
  (let ((text (doc :id "TEST-0001" :extra '("decisions:" "  - OTHER-D1")
                   :body (lines "# T" "### OTHER-D1 — Wrong namespace"
                                "**Status:** Accepted"))))
    (is (has-finding-p (check-one text :rules '("id/format")) "id/format"))))

(test id-unique
  (let ((findings (check-files (list (list "doc/Plan.A.md" (doc :id "TEST-0001"))
                                     (list "doc/Plan.B.md" (doc :id "TEST-0001")))
                               :rules '("id/unique"))))
    (is (= 2 (length findings)) (describe-findings findings))))

(defun decision-doc (&key (id "TEST-0001") (listed '("TEST-D1")) (defined '("TEST-D1"))
                          (status "Accepted"))
  (doc :id id
       :extra (if listed (cons "decisions:" (mapcar (lambda (d) (format nil "  - ~a" d))
                                                    listed))
                  '())
       :body (format nil "# T~%~{### ~a — A decision~%~%**Status:** ~a~%~%~}"
                     (loop for d in defined append (list d status)))))

(test register-mirrored
  (is (null (check-one (decision-doc) :rules '("register/mirrored"))))
  (is (has-finding-p (check-one (decision-doc :listed '()) :rules '("register/mirrored"))
                     "register/mirrored"))
  (is (has-finding-p (check-one (decision-doc :listed '("TEST-D1" "TEST-D9"))
                                :rules '("register/mirrored"))
                     "register/mirrored"))
  ;; Amending a record defined in another document is allowed.
  (is (null (check-files (list (list "doc/Plan.A.md" (decision-doc))
                               (list "doc/Plan.B.md" (decision-doc :id "TEST-0002"
                                                                   :defined '())))
                         :rules '("register/mirrored"))))
  ;; A record in a namespace that is not loaded is unverified, not an error.
  (multiple-value-bind (findings corpus)
      (check-one (decision-doc :listed '("TEST-D1" "ELSEWHERE-D4"))
                 :rules '("register/mirrored"))
    (is (null findings))
    (is (= 1 (length (corpus-unverified corpus))))))

(test register-unique-and-status
  (is (has-finding-p (check-files (list (list "doc/Plan.A.md" (decision-doc))
                                        (list "doc/Plan.B.md" (decision-doc :id "TEST-0002")))
                                  :rules '("register/unique"))
                     "register/unique"))
  (is (has-finding-p (check-one (decision-doc :status "Current") :rules '("register/status"))
                     "register/status"))
  (is (has-finding-p (check-one (doc :extra '("decisions:" "  - TEST-D1")
                                     :body (lines "# T" "### TEST-D1 — No status"))
                                :rules '("register/status"))
                     "register/status"))
  (is (null (check-one (doc :extra '("open-questions:" "  - TEST-O1")
                            :body (lines "# T" "### TEST-O1 — Questions need no status"))
                       :rules '("register/status")))))

(test register-heading-form
  (flet ((form (heading)
           (check-one (doc :extra '("decisions:" "  - TEST-D1")
                           :body (lines "# T" heading "**Status:** Accepted"))
                      :rules '("register/heading-form"))))
    (is (null (form "### TEST-D1 — Full form")))
    (is (has-finding-p (form "### D1 — Short form") "register/heading-form"))
    (is (has-finding-p (form "## TEST-D1 — Wrong level") "register/heading-form"))
    (is (has-finding-p (form "### TEST-D1 - Hyphen") "register/heading-form"))))

(defun memo-doc (&key (genre "Memo") (status "Draft") (read-if "changing the thing")
                      (basis "`src/a.lisp:frob@a1b3f9c`; observed") extra-fields extra)
  (doc :id "TEST-0005" :genre genre :status "Current" :scope "component"
       :extra (append '("memos:" "  - TEST-M1") extra)
       :body (format nil "# T: Memos~%~%## Memos~%~%### TEST-M1 — Frobbing is idempotent~%~%**Status:** ~a~%~@[**Read-if:** ~a~%~]~@[**Basis:** ~a~%~]~{~a~%~}~%Body.~%"
                     status read-if basis extra-fields)))

(test memo-rules
  (let ((findings (check-one (memo-doc) :path "doc/Memo.Test.md"
                                        :rules '("memo/" "register/"))))
    (is (null findings) (describe-findings findings)))
  (is (has-finding-p (check-one (memo-doc :genre "Plan") :rules '("memo/host")) "memo/host"))
  (is (has-finding-p (check-one (memo-doc :read-if nil) :rules '("memo/fields"))
                     "memo/fields"))
  (is (has-finding-p (check-one (memo-doc :basis nil) :rules '("memo/fields"))
                     "memo/fields"))
  (is (has-finding-p (check-one (memo-doc :status "Superseded") :rules '("memo/fields"))
                     "memo/fields"))
  (is (has-finding-p (check-one (memo-doc :extra-fields '("**Superseded-by:** TEST-M2"))
                                :rules '("memo/fields"))
                     "memo/fields"))
  (is (has-finding-p (check-one (memo-doc :extra-fields '("**Recorded:** yesterday"))
                                :rules '("memo/fields"))
                     "memo/fields"))
  (is (has-finding-p (check-one (memo-doc :read-if (make-string 170 :initial-element #\x))
                                :rules '("memo/fields"))
                     "memo/fields" :severity :warning))
  (is (null (check-one (memo-doc :status "Current") :rules '("register/status"))))
  (is (has-finding-p (check-one (memo-doc :status "Accepted") :rules '("register/status"))
                     "register/status")
      "memo records use the memo statuses, not the proposal statuses"))

(test memo-basis
  (flet ((basis (text &rest extra)
           (check-one (memo-doc :basis text :extra extra) :rules '("memo/basis"))))
    (is (null (basis "`src/a.lisp:frob@a1b3f9c`; reproduced")))
    (is (null (basis "decided in TEST-0005") ) "a resolving identifier")
    (is (null (basis "see ELSEWHERE-0003")) "an unloaded namespace is unverified")
    (is (null (basis "per the PEP 1 workflow" "cites:" "  - title: PEP 1"
                     "    locator: Workflow" "    external: true")))
    (is (search "not pinned"
                (finding-message (first (basis "`src/a.lisp:frob`; reproduced")))))
    (is (has-finding-p (basis "we saw it happen") "memo/basis"))))

(test references-in-front-matter
  (let ((files (list (list "doc/Plan.A.md" (doc :id "TEST-0001"
                                                 :extra '("relates-to:" "  - TEST-0002"
                                                          "  - TEST-0009"
                                                          "  - OTHER-0001")))
                     (list "doc/Plan.B.md" (doc :id "TEST-0002")))))
    (multiple-value-bind (findings corpus) (check-files files :rules '("ref/doc-resolves"))
      (is (= 1 (length findings)) (describe-findings findings))
      (is (search "TEST-0009" (finding-message (first findings))))
      (is (= 1 (length (corpus-unverified corpus)))))))

(test references-in-links
  (let* ((a (doc :id "TEST-0001"
                 :body (lines "# T" "## Section"
                              "[TEST-0002](Plan.B.md) [b](Plan.B.md#later)"
                              "[here](#section) [bad anchor](#nowhere)"
                              "[missing](Missing.md) [B by name](Plan.B.md#nope)"
                              "[TEST-0003](Plan.B.md) [up](../README.md)"
                              "[web](https://example.net/x) [away](../../other/X.md)"
                              "![pic](img/none.png) [TEST-D1](Plan.B.md)")))
         (b (doc :id "TEST-0002" :body (lines "# B" "## Later")))
         (findings (check-files (list (list "doc/Plan.A.md" a) (list "doc/Plan.B.md" b)
                                      (list "README.md" (lines "# Readme")))
                                :rules '("ref/doc-resolves")))
         (messages (mapcar #'finding-message findings)))
    (is (= 6 (length findings)) (describe-findings findings))
    (is-true (find-if (lambda (m) (search "#nowhere" m)) messages))
    (is-true (find-if (lambda (m) (search "Missing.md does not exist" m)) messages))
    (is-true (find-if (lambda (m) (search "#nope" m)) messages))
    (is-true (find-if (lambda (m) (search "declares TEST-0002" m)) messages))
    (is-true (find-if (lambda (m) (search "img/none.png" m)) messages))
    (is-true (find-if (lambda (m) (search "record TEST-D1" m)) messages))))

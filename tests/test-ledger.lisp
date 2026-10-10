;;;; test-ledger.lisp — Tests for the ledger: its format, its rules, and resolution through aliases

(in-package #:compass.tests)

(def-suite ledger :in compass)
(in-suite ledger)

;;; Format

(test ledger-format-round-trip
  (let* ((line (entry-line "TEST-0002" :document :draft "TEST-DRAFT-alpha"
                                                 :path "doc/Plan.A.md"))
         (entries (parse-ledger-text (ledger-file line
                                                  (entry-line "TEST-D1" :decision
                                                              :draft "TEST-DRAFT-alpha-D1"
                                                              :host "TEST-0002")))))
    (is (string= "(:id \"TEST-0002\" :kind :document :draft \"TEST-DRAFT-alpha\" :path \"doc/Plan.A.md\" :date \"2026-10-09\" :by \"Tester\")"
                 line))
    (is (= 2 (length entries)))
    (is (equal "TEST-DRAFT-alpha" (ledger-entry-draft (first entries))))
    (is (eq :decision (ledger-entry-kind (second entries))))
    (is (equal "TEST-0002" (ledger-entry-host (second entries))))
    (is (= 4 (ledger-entry-line (first entries))) "after the three-line header")
    (is (equal line (ledger-entry-text (first entries))))))

(test ledger-text-appends
  (let ((entry (make-ledger-entry :id "TEST-0001" :kind :document :path "Compass.md"
                                  :date "2026-10-09" :by "A \"quoted\" name")))
    (let ((new (ledger-text-with-entries nil (list entry) :namespaces '("TEST"))))
      (is (starts-with-p ";;; Compass allocation ledger for TEST." new))
      (is (search "A \\\"quoted\\\" name" new))
      (is (equal "A \"quoted\" name" (ledger-entry-by (first (parse-ledger-text new))))))
    (let ((new (ledger-text-with-entries "; no final newline" (list entry))))
      (is (starts-with-p (format nil "; no final newline~%(:id") new)))))

(defun ledger-problems-in (text)
  (nth-value 1 (parse-ledger-text text :path "doc/REGISTRY.sexp")))

(test ledger-malformed-lines
  (flet ((problem (line)
           (let ((findings (ledger-problems-in (ledger-file line))))
             (and findings (finding-message (first findings))))))
    (is (search "merge-conflict marker" (problem "<<<<<<< HEAD")))
    (is (search "merge-conflict marker" (problem "=======")))
    (is (search "property list" (problem "(\"TEST-0001\")")))
    (is (search "exactly one entry" (problem "(:id \"TEST-0001\") (:id \"TEST-0002\")")))
    (is (search "not a canonical" (problem (entry-line "TEST-DRAFT-a" :document :path "x"))))
    (is (search "does not match" (problem (entry-line "TEST-D1" :document :path "x"))))
    (is (search "needs :host" (problem (entry-line "TEST-D1" :decision))))
    (is (search "needs :path" (problem (entry-line "TEST-0001" :document))))
    (is (search "YYYY-MM-DD" (problem (entry-line "TEST-0001" :document :path "x"
                                                               :date "10/09/2026"))))
    (is (search "not a provisional" (problem (entry-line "TEST-0001" :document :path "x"
                                                                     :draft "TEST-0009"))))
    (is (search "reader syntax" (problem "#.(delete-file \"x\")"))))
  (let ((findings (ledger-problems-in
                   (ledger-file "(:id \"TEST-0001\" :kind :document :path \"x\" :date \"2026-10-09\" :by \"T\" :colour \"blue\")"))))
    (is (= 1 (length findings)))
    (is (eq :warning (finding-severity (first findings))))))

;;; Rules

(test ledger-valid-is-reported-on-load
  (let ((findings (check-with-ledger (list (list "doc/Plan.A.md" (doc)))
                                     (ledger-file "not an entry"))))
    (is (has-finding-p findings "ledger/valid" :path "doc/REGISTRY.sexp" :line 4))))

(test ledger-coverage
  (let ((files (list (list "doc/Plan.A.md" (canonical-doc "TEST-0001")))))
    (let ((findings (check-with-ledger files nil :rules '("ledger/coverage"))))
      (is (= 1 (length findings)))
      (is (search "has no ledger" (finding-message (first findings)))))
    (let ((findings (check-with-ledger files (ledger-file) :rules '("ledger/coverage"))))
      (is (search "is not in the ledger" (finding-message (first findings)))))
    (is (null (check-with-ledger files (ledger-file (entry-line "TEST-0001" :document
                                                                :path "doc/Plan.A.md"))
                                 :rules '("ledger/coverage")))))
  ;; A provisional identifier the ledger has assigned must not still be defined.
  (let ((findings (check-with-ledger
                   (list (list "doc/Plan.A.md" (doc :id "TEST-DRAFT-alpha")))
                   (ledger-file (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                                  :path "doc/Plan.A.md"))
                   :rules '("ledger/coverage"))))
    (is (search "was assigned TEST-0001" (finding-message (first findings)))))
  ;; Namespaces this repository does not own are not its to cover.
  (is (null (check-with-ledger (list (list "doc/Plan.A.md" (canonical-doc "OTHER-0001")))
                               (ledger-file) :rules '("ledger/coverage")))))

(test ledger-rules-need-declared-namespaces
  (is (null (check-files (list (list "doc/Plan.A.md" (canonical-doc "TEST-0001")))
                         :rules '("ledger/")))))

(test ledger-unique
  (let ((findings (check-with-ledger
                   (list (list "doc/Plan.A.md" (canonical-doc "TEST-0001")))
                   (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.A.md"
                                                                  :draft "TEST-DRAFT-a")
                                (entry-line "TEST-0001" :document :path "doc/Plan.B.md"
                                                                  :draft "TEST-DRAFT-b")
                                (entry-line "TEST-0002" :document :path "doc/Plan.C.md"
                                                                  :draft "TEST-DRAFT-a"))
                   :rules '("ledger/unique"))))
    (is (= 2 (length findings)) (describe-findings findings))
    (is (has-finding-p findings "ledger/unique" :line 5))
    (is (has-finding-p findings "ledger/unique" :line 6))))

(test ledger-owned-namespace
  (let ((findings (check-with-ledger
                   (list (list "doc/Plan.A.md" (canonical-doc "OTHER-0001")))
                   (ledger-file (entry-line "OTHER-0002" :document :path "x"))
                   :rules '("ledger/owned-namespace"))))
    (is (= 2 (length findings)) (describe-findings findings))
    (is (has-finding-p findings "ledger/owned-namespace" :path "doc/REGISTRY.sexp"))
    (is (has-finding-p findings "ledger/owned-namespace" :path "doc/Plan.A.md"))))

(test ledger-git-rules-note-when-git-is-absent
  (multiple-value-bind (findings corpus)
      (check-with-ledger (list (list "doc/Plan.A.md" (doc)))
                         (ledger-file) :rules '("ledger/append-only" "ledger/no-union-merge"))
    (is (null findings))
    (is (= 2 (length (corpus-notes corpus))))
    (is (search "not a Git repository" (first (corpus-notes corpus))))))

(test ledger-append-only
  (let ((line1 (entry-line "TEST-0001" :document :path "doc/Plan.A.md")))
    (with-git-repository (root (list (list "compass.sexp" *ledger-manifest*)
                                     (list "doc/Plan.A.md" (canonical-doc "TEST-0001"))
                                     (list "doc/REGISTRY.sexp" (ledger-file line1))))
      (flet ((append-only-findings ()
               (check-corpus (load-corpus root) :only '("ledger/append-only"))))
        (is (null (append-only-findings)))
        (write-file root "doc/REGISTRY.sexp"
                    (ledger-file line1 (entry-line "TEST-0002" :document :path "doc/Plan.B.md")))
        (is (null (append-only-findings)) "appending is allowed")
        (write-file root "doc/REGISTRY.sexp"
                    (ledger-file (entry-line "TEST-0001" :document :path "doc/Plan.A.md"
                                                                   :date "2026-10-10")))
        (let ((findings (append-only-findings)))
          (is (has-finding-p findings "ledger/append-only" :line 4)))
        (delete-file (root-file root "doc/REGISTRY.sexp"))
        (is (search "was deleted" (finding-message (first (append-only-findings)))))))))

(test ledger-no-union-merge
  (with-git-repository (root (list (list "compass.sexp" *ledger-manifest*)
                                   (list "doc/Plan.A.md" (doc))
                                   (list "doc/REGISTRY.sexp" (ledger-file))))
    (is (null (check-corpus (load-corpus root) :only '("ledger/no-union-merge"))))
    (write-file root ".gitattributes" (lines "doc/REGISTRY.sexp merge=union"))
    (is (has-finding-p (check-corpus (load-corpus root) :only '("ledger/no-union-merge"))
                       "ledger/no-union-merge"))))

;;; Aliases

(defparameter *aliased-files*
  (list (list "doc/Plan.A.md"
              (canonical-doc "TEST-0001"
                             :extra '("decisions:" "  - TEST-D1")
                             :body (lines "# Alpha" "## Settled Decisions"
                                          "### TEST-D1 — Use a ledger" ""
                                          "**Status:** Accepted")))
        (list "doc/Plan.B.md"
              (doc :id "TEST-DRAFT-beta"
                   :extra '("relates-to:" "  - TEST-DRAFT-alpha")
                   :body (lines "# Beta" "As TEST-DRAFT-alpha-D1 decided, see"
                                "[the plan](Plan.A.md).")))))

(defparameter *aliased-ledger*
  (ledger-file (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha" :path "doc/Plan.A.md")
               (entry-line "TEST-D1" :decision :draft "TEST-DRAFT-alpha-D1" :host "TEST-0001")))

(test aliases-resolve
  (with-temp-repository (root (list* (list "compass.sexp" *ledger-manifest*)
                                     (list "doc/REGISTRY.sexp" *aliased-ledger*)
                                     *aliased-files*))
    (let ((corpus (load-corpus root)))
      (is (equal "TEST-0001" (corpus-alias-target corpus "TEST-DRAFT-alpha")))
      (is (equal '("TEST-0001" "TEST-DRAFT-alpha") (corpus-names-of corpus "TEST-0001")))
      (multiple-value-bind (object container via) (resolve corpus "TEST-DRAFT-alpha-D1")
        (is (equal "TEST-D1" (record-id object)))
        (is (equal "doc/Plan.A.md" (document-path container)))
        (is (equal "TEST-D1" via)))
      (multiple-value-bind (text path first last via) (show corpus "TEST-DRAFT-alpha#alpha")
        (declare (ignore text first last))
        (is (equal "doc/Plan.A.md" path))
        (is (equal "TEST-0001" via)))
      (let ((outline (document-outline corpus "TEST-DRAFT-alpha")))
        (is (equal "TEST-0001" (outline-id outline)))
        (is (equal "TEST-DRAFT-alpha" (outline-alias outline))))
      (let ((references (find-references corpus "TEST-0001")))
        (is (= 2 (length references)))
        (is (equal "TEST-DRAFT-alpha"
                   (inbound-reference-name
                    (find :relation references :key #'inbound-reference-kind)))))
      (let ((references (find-references corpus "TEST-D1")))
        (is (= 1 (length references)))
        (is (equal "TEST-DRAFT-alpha-D1" (inbound-reference-name (first references))))))))

(test stale-alias-warnings
  (let ((findings (check-with-ledger *aliased-files* *aliased-ledger*
                                     :rules '("ref/stale-alias"))))
    (is (= 2 (length findings)) (describe-findings findings))
    (is (has-finding-p findings "ref/stale-alias" :path "doc/Plan.B.md" :severity :warning))
    (is (search "write TEST-D1" (finding-message (second findings))))))

(test provisional-records-in-numbered-documents
  (flet ((record-findings (record-id)
           (check-with-ledger
            (list (list "doc/Plan.A.md"
                        (canonical-doc "TEST-0001"
                                       :extra (list "decisions:" (format nil "  - ~a" record-id))
                                       :body (lines "# Alpha"
                                                    (format nil "### ~a — New" record-id)
                                                    "**Status:** Proposed")))
                  (list "doc/Plan.B.md" (doc :id "TEST-DRAFT-beta")))
            (ledger-file (entry-line "TEST-0001" :document :draft "TEST-DRAFT-alpha"
                                                           :path "doc/Plan.A.md"))
            :rules '("id/format"))))
    (is (null (record-findings "TEST-DRAFT-alpha-D2")) "the document's own alias")
    (is (has-finding-p (record-findings "TEST-DRAFT-beta-D1") "id/format")
        "another document's identifier")
    (is (null (record-findings "TEST-DRAFT-unused-D1")) "a slug no document uses")))

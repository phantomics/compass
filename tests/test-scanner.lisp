;;;; test-scanner.lisp — Tests for the body scanner, inline scanning, and anchors

(in-package #:compass.tests)

(def-suite scanner :in compass)
(in-suite scanner)

(defun body-of (&rest lines)
  (parse-document (doc :body (format nil "~{~a~%~}" lines)) :path "doc/x.md"))

(test github-anchors
  (is (equal "dependency-management-quicklisp-and-ocicl"
             (heading-anchor "Dependency management: Quicklisp and ocicl")))
  (is (equal "compass-draft-toolchain-d1--merge-time-ledger"
             (heading-anchor "COMPASS-DRAFT-toolchain-D1 — Merge-time ledger")))
  (is (equal "compassheader-block" (heading-anchor "`compass:header` block")))
  (is (equal "see-the-guide" (heading-anchor "See [the guide](g.md)")))
  (is (equal "émigré-café" (heading-anchor "Émigré Café")))
  (is (equal "snake_case-names" (heading-anchor "snake_case names"))))

(test repeated-anchors
  (let ((d (body-of "# T" "## Notes" "## Notes" "## Notes-1" "## Notes")))
    (is (equal '("t" "notes" "notes-1" "notes-1-1" "notes-2") (document-anchors d)))))

(test fences-hide-structure
  (let ((d (body-of "# Title" "```markdown" "## Not a heading" "[x](missing.md)"
                    "### PSYCHE-D16 — Example" "```" "## Real")))
    (is (equal '("title" "real") (document-anchors d)))
    (is (null (document-links d)))
    (is (null (document-records d)))
    (is (= 1 (length (document-fences d))))))

(test comments-hide-structure
  (let ((d (body-of "# Title" "<!-- optional:" "## Hidden" "[x](missing.md)" "-->"
                    "Text with <!-- [y](inline.md) --> an inline comment.")))
    (is (equal '("title") (document-anchors d)))
    (is (null (document-links d)))))

(test code-spans-and-links
  (let ((d (body-of "# T" "A `[not](a-link.md)` and [real](r.md) and ![img](i.png)."
                    "A span `across"
                    "lines [x](y.md)` then [z](z.md \"title\").")))
    (is (equal '("r.md" "z.md") (mapcar #'link-target (document-links d))))
    (is (equal '("i.png") (mapcar #'link-target (document-images d))))
    (is (equal "across lines [x](y.md)"
               (code-span-text (second (document-code-spans d)))))
    (let ((link (first (document-links d))))
      (is (= 12 (location-line link)) "line numbers count the front-matter")
      (is (= 26 (location-column link))))))

(test nested-image-link
  (let ((d (body-of "# T" "[![badge](b.svg)](https://example.net)")))
    (is (equal '("https://example.net") (mapcar #'link-target (document-links d))))
    (is (equal '("b.svg") (mapcar #'link-target (document-images d))))))

(test records-and-fields
  (let* ((d (parse-document
             (doc :id "COMPASS-DRAFT-x"
                  :body (lines "# T" "## Settled Decisions" ""
                               "### COMPASS-DRAFT-x-D1 — First decision" ""
                               "**Status:** Accepted"
                               "**Context:** Some context"
                               "that wraps." ""
                               "**Decision:** Do it."
                               "#### Detail" "More."
                               "### D2 -- Short form" "**Status:** Proposed"
                               "## Next"))
             :path "doc/x.md"))
         (records (document-records d)))
    (is (= 2 (length records)))
    (let ((r (first records)))
      (is (equal "COMPASS-DRAFT-x-D1" (record-id r)))
      (is (equal "First decision" (record-title r)))
      (is (equal "Accepted" (record-field r "Status")))
      (is (equal "Some context that wraps." (record-field r "Context")))
      (is (equal "Do it." (record-field r "Decision"))))
    (let ((r (second records)))
      (is-true (record-short-form-p r))
      (is (equal "COMPASS-D2" (record-id r)))
      (is (equal "--" (record-separator r))))))

(test tables-and-captions
  (let* ((d (body-of "# T" "Table: Things and" "their uses." ""
                     "| A | B \\| C |" "|---|---|" "| 1 | 2 |" ""
                     "| X |" "|:--|" "| 3 |"))
         (tables (document-tables d)))
    (is (= 2 (length tables)))
    (is (equal "Things and their uses." (table-caption (first tables))))
    (is (equal '("A" "B \\| C") (table-header-cells (first tables))))
    (is (null (table-caption (second tables))))))

(test front-matter-splitting
  (let ((d (parse-document (format nil "---~%id: X-0001~%---~%# T~%") :path "a.md")))
    (is-true (document-has-front-matter-p d))
    (is (equal "X-0001" (document-id d)))
    (is (= 4 (document-body-start-line d))))
  (let ((d (parse-document (format nil "# No front-matter~%") :path "a.md")))
    (is-false (document-has-front-matter-p d)))
  (let ((d (parse-document (format nil "---~%id: X~%# never closed~%") :path "a.md")))
    (is (has-finding-p (document-load-findings d) "fm/syntax"))))

(test code-references
  (let ((r (parse-code-reference "src/ledger.lisp:read-ledger@a1b3f9c")))
    (is (equal "src/ledger.lisp" (code-reference-path r)))
    (is (equal "read-ledger" (code-reference-symbol r)))
    (is (equal "a1b3f9c" (code-reference-revision r))))
  (let ((r (parse-code-reference "ORIGIN:src/m.lisp#L233-L248@v1.2.0")))
    (is (equal "ORIGIN" (code-reference-namespace r)))
    (is (= 233 (code-reference-line-start r)))
    (is (= 248 (code-reference-line-end r))))
  (is (null (parse-code-reference "src/ledger.lisp:read-ledger")))
  (is (null (parse-code-reference "src/x.lisp:42"))))

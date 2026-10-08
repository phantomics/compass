;;;; test-yaml.lisp — Tests for the strict YAML-subset parser (COMPASS-DRAFT-toolchain-D18)

(in-package #:compass.tests)

(def-suite yaml :in compass)
(in-suite yaml)

(defun yaml (&rest lines)
  (parse-yaml-subset (format nil "~{~a~%~}" lines)))

(defun scalar (mapping key)
  (let ((node (yaml-get mapping key)))
    (and node (not (yaml-null-p node)) (yaml-scalar-value node))))

(defun rejects (message-part &rest lines)
  "True if LINES are rejected with a message containing MESSAGE-PART."
  (handler-case (progn (apply #'yaml lines) nil)
    (front-matter-syntax-error (e)
      (or (search message-part (front-matter-syntax-error-message e))
          (error "rejected with an unexpected message: ~a"
                 (front-matter-syntax-error-message e))))))

(test scalars-stay-strings
  (let ((m (yaml "language: no" "schema-version: 0.10" "created: 2026-10-07"
                 "flag: true" "count: 3")))
    (is (equal "no" (scalar m "language")))
    (is (equal "0.10" (scalar m "schema-version")))
    (is (equal "2026-10-07" (scalar m "created")))
    (is (equal "true" (scalar m "flag")))
    (is (equal "3" (scalar m "count")))))

(test quoted-scalars
  (let ((m (yaml "a: \"x: y \\\"q\\\" \\u00e9\"" "b: 'it''s # not a comment'"
                 "c: \"with # hash\"   # trailing comment")))
    (is (equal "x: y \"q\" é" (scalar m "a")))
    (is (equal "it's # not a comment" (scalar m "b")))
    (is (equal "with # hash" (scalar m "c")))))

(test plain-scalars-and-comments
  (let ((m (yaml "title: Plan — with a dash   # comment"
                 "url: https://example.net/a#frag"
                 "locator: SPEC §7")))
    (is (equal "Plan — with a dash" (scalar m "title")))
    (is (equal "https://example.net/a#frag" (scalar m "url")))
    (is (equal "SPEC §7" (scalar m "locator")))))

(test nulls
  (let ((m (yaml "a: ~" "b: null" "c:" "d:   # just a comment" "e: Null")))
    (dolist (key '("a" "b" "c" "d" "e"))
      (is-true (yaml-null-p (yaml-get m key)) "~a should be null" key))))

(test sequences
  (let ((m (yaml "authors:" "  - Ada" "  - Andrew Sengul"
                 "relates-to:" "- COMPASS-0001"
                 "tags: [a, \"b c\", 'd']" "empty: []")))
    (is (equal '("Ada" "Andrew Sengul")
               (mapcar #'yaml-scalar-value (yaml-sequence-items (yaml-get m "authors")))))
    (is (equal '("COMPASS-0001")
               (mapcar #'yaml-scalar-value (yaml-sequence-items (yaml-get m "relates-to")))))
    (is (equal '("a" "b c" "d")
               (mapcar #'yaml-scalar-value (yaml-sequence-items (yaml-get m "tags")))))
    (is (null (yaml-sequence-items (yaml-get m "empty"))))))

(test sequences-of-mappings-and-nesting
  (let* ((m (yaml "cites:"
                  "  - title:   PEP 1"
                  "    locator: \"Workflow\""
                  "    external: true"
                  "  - title: Second"
                  "    external: true"
                  "provenance:"
                  "  assistant:   opencode"
                  "  session: s1"))
         (cites (yaml-sequence-items (yaml-get m "cites"))))
    (is (= 2 (length cites)))
    (is (equal "PEP 1" (scalar (first cites) "title")))
    (is (equal "Workflow" (scalar (first cites) "locator")))
    (is (equal "true" (scalar (second cites) "external")))
    (is (equal "opencode" (scalar (yaml-get m "provenance") "assistant")))))

(test positions
  (let* ((m (parse-yaml-subset (format nil "id: X~%authors:~%  - Ada~%") :start-line 2))
         (item (first (yaml-sequence-items (yaml-get m "authors")))))
    (is (= 2 (yaml-entry-line (yaml-get-entry m "id"))))
    (is (= 4 (yaml-node-line item)))
    (is (= 5 (yaml-node-column item)))))

(test rejections
  (is-true (rejects "tab" (format nil "a:~%~Cb: c" #\Tab)))
  (is-true (rejects "duplicate key" "a: 1" "a: 2"))
  (is-true (rejects "anchors" "a: &x 1"))
  (is-true (rejects "aliases" "a: *x"))
  (is-true (rejects "tags" "a: !!str 1"))
  (is-true (rejects "block scalars" "a: |" "  text"))
  (is-true (rejects "flow mappings" "a: {b: 1}"))
  (is-true (rejects "explicit keys" "? a" ": b"))
  (is-true (rejects "\": \"" "status: Superseded-by: PSYCHE-0002"))
  (is-true (rejects "same line" "a: x" "b: \"open"))
  (is-true (rejects "multi-line" "title: one" "  two"))
  (is-true (rejects "document markers" "a: 1" "..."))
  (is-true (rejects "nested flow" "a: [b, [c]]"))
  (is-true (rejects "space is required" "a:b"))
  (is-true (rejects "quoted keys" "\"a\": b"))
  (is-true (rejects "mapping of keys" "- a" "- b"))
  (is-true (rejects "unsupported escape" "a: \"\\q\""))
  (is-true (rejects "only a # comment" "a: \"x\"y")))

(test empty-front-matter
  (is (null (yaml-mapping-entries (parse-yaml-subset "")))))

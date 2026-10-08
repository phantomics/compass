;;;; test-identifier.lisp — Tests for identifier parsing

(in-package #:compass.tests)

(def-suite identifier :in compass)
(in-suite identifier)

(test canonical-identifiers
  (let ((id (parse-identifier "COMPASS-0001")))
    (is (eq :document (identifier-kind id)))
    (is (equal "COMPASS" (identifier-namespace id)))
    (is (= 1 (identifier-serial id)))
    (is-false (identifier-provisional-p id)))
  (is (eq :decision (identifier-kind (parse-identifier "PSYCHE-D16"))))
  (is (eq :open-question (identifier-kind (parse-identifier "ORIGIN-O9"))))
  (is (eq :memo (identifier-kind (parse-identifier "CLASSIC-M3"))))
  (is (= 12345 (identifier-serial (parse-identifier "LEXTER-12345")))))

(test provisional-identifiers
  (let ((id (parse-identifier "COMPASS-DRAFT-toolchain")))
    (is (eq :document (identifier-kind id)))
    (is-true (identifier-provisional-p id))
    (is (equal "toolchain" (identifier-slug id))))
  (let ((id (parse-identifier "COMPASS-DRAFT-agent-workflow-D11")))
    (is (eq :decision (identifier-kind id)))
    (is (= 11 (identifier-serial id)))
    (is (equal "COMPASS-DRAFT-agent-workflow" (identifier-host id))))
  (is (eq :memo (identifier-kind (parse-identifier "CLASSIC-DRAFT-federation-M2")))))

(test invalid-identifiers
  (dolist (s '("COMPASS-1" "compass-0001" "COMPASS-DRAFT-Toolchain" "COMPASS-D0"
               "COMPASS-DRAFT-" "COMPASS" "COMPASS-X1" "COMPASS-DRAFT-a--b" ""))
    (is (null (parse-identifier s)) "~s should not parse" s))
  (is (search "zero-padded" (diagnose-identifier "COMPASS-7")))
  (is (search "record identifier" (diagnose-identifier "COMPASS-D1")))
  (is (search "lowercase" (diagnose-identifier "COMPASS-DRAFT-Foo")))
  (is (null (diagnose-identifier "COMPASS-0001"))))

(test formatting-and-references
  (is (equal "COMPASS-0007" (format-canonical-identifier "COMPASS" :document 7)))
  (is (equal "COMPASS-M12" (format-canonical-identifier "COMPASS" :memo 12)))
  (multiple-value-bind (id anchor) (split-reference "COMPASS-0003#the-ledger")
    (is (equal "COMPASS-0003" id))
    (is (equal "the-ledger" anchor))))

(test identifiers-in-text
  (is (equal '("COMPASS-0001" "COMPASS-DRAFT-toolchain-D1" "ORIGIN-O9")
             (find-identifiers-in-text
              "See COMPASS-0001, then COMPASS-DRAFT-toolchain-D1 and ORIGIN-O9.")))
  (is (null (find-identifiers-in-text "UTF-8 and SHA-256 are not identifiers"))))

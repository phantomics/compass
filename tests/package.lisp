;;;; package.lisp — The test package and the suite runner
;;;;
;;;; Read-if: adding a test suite or changing how the suite is run
;;;; See: COMPASS-DRAFT-toolchain

(defpackage #:compass.tests
  (:use #:cl #:fiveam #:compass)
  (:shadowing-import-from #:fiveam #:run)
  (:export #:run-tests))

(in-package #:compass.tests)

(def-suite compass :description "The Compass toolchain test suite")

(defun run-tests ()
  "Run every suite. Return true if all tests pass."
  (let ((results (fiveam:run 'compass)))
    (fiveam:explain! results)
    (fiveam:results-status results)))

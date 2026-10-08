;;;; test-cli.lisp — Tests for the command line: exit codes, output formats, and usage errors

(in-package #:compass.tests)

(def-suite cli :in compass)
(in-suite cli)

(defun run-cli (&rest args)
  "Run compass with ARGS. Return the exit code, standard output, and error output."
  (let* ((out (make-string-output-stream))
         (err (make-string-output-stream))
         (code (let ((*standard-output* out) (*error-output* err))
                 (main args :exit nil))))
    (values code (get-output-stream-string out) (get-output-stream-string err))))

(defun root-arg (root) (format nil "--root=~a" (uiop:native-namestring root)))

(test check-exit-codes
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc))))
    (multiple-value-bind (code out) (run-cli "check" (root-arg root))
      (is (= 0 code))
      (is (search "Checked 1 document: 0 errors, 0 warnings." out))))
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :genre "Nonsense"))))
    (multiple-value-bind (code out) (run-cli "check" (root-arg root))
      (is (= 1 code))
      (is (search "doc/Plan.A.md:4:8: error vocab/genre:" out))))
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :extra '("colour: blue")))))
    (is (= 0 (run-cli "check" (root-arg root))))
    (is (= 1 (run-cli "check" "--strict" (root-arg root))))))

(test check-json
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :scope "team"))))
    (multiple-value-bind (code out) (run-cli "check" "--format" "json" (root-arg root))
      (is (= 1 code))
      (let* ((json (shasht:read-json out))
             (findings (gethash "findings" json)))
        (is (equal "compass" (gethash "tool" json)))
        (is (= 1 (gethash "errors" (gethash "summary" json))))
        (is (equal "vocab/scope" (gethash "rule" (aref findings 0))))
        (is (equal "doc/Plan.A.md" (gethash "path" (aref findings 0))))))))

(test check-rule-selection-and-paths
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :scope "team"))
                                    (list "doc/Plan.B.md" (doc :id "TEST-0002"
                                                               :genre "Nonsense"))))
    (is (= 1 (run-cli "check" "--rule" "vocab/scope" (root-arg root))))
    (is (= 0 (run-cli "check" "--rule" "fm" (root-arg root))))
    (is (= 0 (run-cli "check" "--exclude" "vocab" (root-arg root))))
    (let ((*default-pathname-defaults* root))
      (multiple-value-bind (code out)
          (run-cli "check" (root-arg root)
                   (uiop:native-namestring (merge-pathnames "doc/Plan.A.md" root)))
        (is (= 1 code))
        (is (not (search "Plan.B.md" out)))))))

(test show-and-next
  (with-temp-repository (root (list (list "doc/Plan.A.md" (doc :body (lines "# T" "## Part" "Text.")))))
    (multiple-value-bind (code out) (run-cli "show" "TEST-0001#part" (root-arg root))
      (is (= 0 code))
      (is (search (lines "## Part" "Text.") out)))
    (multiple-value-bind (code out err) (run-cli "show" "TEST-0404" (root-arg root))
      (is (= 1 code))
      (is (string= "" out))
      (is (search "not defined" err)))
    (multiple-value-bind (code out err) (run-cli "next" "TEST" (root-arg root))
      (is (= 0 code))
      (is (equal (lines "TEST-0002") out))
      (is (search "advisory" err)))))

(test usage-errors
  (is (= 2 (run-cli)))
  (is (= 2 (run-cli "frobnicate")))
  (is (= 2 (run-cli "check" "--colour")))
  (is (= 2 (run-cli "check" "--format" "xml")))
  (is (= 2 (run-cli "check" "--rule" "no/such-rule")))
  (is (= 2 (run-cli "next" "lowercase")))
  (multiple-value-bind (code out err) (run-cli "check" "--format")
    (declare (ignore out))
    (is (= 2 code))
    (is (search "needs a value" err))))

(test help-version-rules
  (multiple-value-bind (code out) (run-cli "help")
    (is (= 0 code))
    (is (search "check" out)))
  (multiple-value-bind (code out) (run-cli "version")
    (is (= 0 code))
    (is (starts-with-p (format nil "compass ~a" +version+) out)))
  (multiple-value-bind (code out) (run-cli "rules" "--format" "json")
    (is (= 0 code))
    (let ((rules (shasht:read-json out)))
      (is (find "memo/basis" rules :key (lambda (r) (gethash "name" r)) :test #'equal))
      (is (find "fm/syntax" rules :key (lambda (r) (gethash "name" r)) :test #'equal)))))

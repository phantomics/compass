;;;; test-sexp.lisp — Tests for the restricted reader and the manifest

(in-package #:compass.tests)

(def-suite sexp :in compass)
(in-suite sexp)

(test restricted-reader-accepts-data
  (is (equal '((:namespaces ("A" "B") :count 3 :neg -2))
             (read-restricted-sexps
              (format nil ";; comment~%(:namespaces (\"A\" \"B\") :count 3 :neg -2)"))))
  (is (equal '("a\"b\\c") (read-restricted-sexps "\"a\\\"b\\\\c\""))))

(test restricted-reader-rejects-code
  (dolist (input '("#.(delete-file \"x\")" "(foo bar)" "'x" "`(a ,b)" "(a . b)"
                   "|sym|" "1.5" "#p\"/tmp\"" "(:a" ":a)" "\"unterminated"
                   "\"bad \\n escape\"" "123456789012345678901234567890"))
    (signals sexp-syntax-error (read-restricted-sexps input)
      "~s should be rejected" input)))

(test restricted-reader-interns-nothing
  (let* ((name (format nil "COMPASS-TEST-NEVER-INTERNED-~d" (random 1000000)))
         (form (first (read-restricted-sexps (format nil ":~a" name)))))
    (is-true (foreign-keyword-p form))
    (is (equal name (foreign-keyword-name form)))
    (is (null (find-symbol name "KEYWORD")))))

(test restricted-reader-limits-depth
  (signals sexp-syntax-error
    (read-restricted-sexps (concatenate 'string (make-string 100 :initial-element #\()
                                        (make-string 100 :initial-element #\))))))

(defun manifest-from (text)
  (with-temp-repository (root (list (list "compass.sexp" text)))
    (read-manifest (merge-pathnames "compass.sexp" root))))

(test manifest-reads-keys
  (multiple-value-bind (manifest findings)
      (manifest-from "(:namespaces (\"ORIGIN\") :doc-directory \"docs\"
                       :federation ((:namespace \"CLASSIC\" :path \"../classic\"))
                       :commands ((:name :test :repl \"(asdf:test-system \\\"x\\\")\"))
                       :stewards ((:namespace \"ORIGIN\" :steward \"Ada\" :approval :solo)))")
    (is (null findings) (describe-findings findings))
    (is (equal '("ORIGIN") (manifest-namespaces manifest)))
    (is (equal "docs/" (manifest-doc-directory manifest)))
    (is (equal "CLASSIC" (federation-entry-namespace (first (manifest-federation manifest)))))
    (is (eq :repl (command-kind (first (manifest-commands manifest)))))
    (is (eq :solo (steward-approval (first (manifest-stewards manifest)))))))

(test manifest-problems-become-findings
  (multiple-value-bind (manifest findings) (manifest-from "#.(launch-missiles)")
    (is (equal "doc/" (manifest-doc-directory manifest)))
    (is (has-finding-p findings "manifest/valid" :severity :error)))
  (multiple-value-bind (manifest findings)
      (manifest-from "(:namespaces (\"lower\") :doc-directory \"../outside\" :colour 3)")
    (declare (ignore manifest))
    (is (= 3 (length findings)) (describe-findings findings))
    (is (has-finding-p findings "manifest/valid" :severity :warning))))

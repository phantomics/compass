;;;; test-util.lisp — Tests for string, path, and file helpers

(in-package #:compass.tests)

(def-suite util :in compass)
(in-suite util)

(test split-lines
  (is (equalp #("a" "b") (split-lines (format nil "a~%b~%"))))
  (is (equalp #("a" "b") (split-lines (format nil "a~C~%b" #\Return))))
  (is (equalp #("a" "" "b") (split-lines (format nil "a~%~%b"))))
  (is (equalp #() (split-lines "")))
  (is (equalp #("") (split-lines (string #\Newline)))))

(test valid-dates
  (is-true (valid-date-string-p "2026-10-07"))
  (is-true (valid-date-string-p "2024-02-29"))
  (is-false (valid-date-string-p "2026-02-29"))
  (is-false (valid-date-string-p "1900-02-29"))
  (is-false (valid-date-string-p "2026-13-01"))
  (is-false (valid-date-string-p "10.07.2026"))
  (is-false (valid-date-string-p "2026-1-07")))

(test normalize-relative-path
  (is (equal "Compass.md" (normalize-relative-path "doc/" "../Compass.md")))
  (is (equal "doc/Plan.X.md" (normalize-relative-path "doc/" "./Plan.X.md")))
  (is (equal "skills/" (normalize-relative-path "doc/" "../skills/")))
  (is (equal "" (normalize-relative-path "" ".")))
  (multiple-value-bind (path escapes) (normalize-relative-path "doc/" "../../psyche/X.md")
    (declare (ignore path))
    (is-true escapes)))

(test edit-distance-and-closest-match
  (is (= 0 (edit-distance "abc" "abc")))
  (is (= 1 (edit-distance "relates-to" "relate-to")))
  (is (equal "relates-to" (closest-match "relates_to" '("relates-to" "title"))))
  (is (null (closest-match "zzzzzz" '("relates-to" "title")))))

(test percent-decode
  (is (equal "a b.md" (percent-decode "a%20b.md")))
  (is (equal "é" (percent-decode "%C3%A9")))
  (is (equal "100%" (percent-decode "100%"))))

(test relative-path-string
  (is (equal "doc/Plan.X.md"
             (relative-path-string #p"/r/doc/Plan.X.md" #p"/r/")))
  (is (equal "Compass.md" (relative-path-string #p"/r/Compass.md" #p"/r/"))))

(test text-files-round-trip
  (with-temp-repository (root '())
    (let ((path (root-file root "x/é.md"))
          (text (format nil "—§ ünïcode~%")))
      (write-text-file path text)
      (is (equal text (read-text-file path))))))

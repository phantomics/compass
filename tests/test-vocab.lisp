;;;; test-vocab.lisp — Tests for the controlled vocabularies and their sync with the skills

(in-package #:compass.tests)

(def-suite vocab :in compass)
(in-suite vocab)

(test genres
  (is (= 11 (length (genres))))
  (is (equal "Arch." (genre-prefix (find-genre "Architecture"))))
  (is (eq (find-genre "Architecture") (find-genre-by-prefix "Arch")))
  (is (eq :memo (genre-family (find-genre "Memo"))))
  (is (eq :accepted (genre-standing (find-genre "Memo"))))
  (is (null (find-genre "Concept"))))

(test status-families
  (is-true (find-genre-status (find-genre "Plan") "Design-Record"))
  (is-false (find-genre-status (find-genre "Plan") "Current"))
  (is-true (find-genre-status (find-genre "Ref") "Current"))
  (is-true (find-genre-status (find-genre "Memo") "Superseded"))
  (is (eq :accepted (term-standing (find-genre-status (find-genre "Memo") "Superseded"))))
  (is (eq :pending (term-standing (find-genre-status (find-genre "Plan") "Superseded"))))
  (is (equal "COMPASS-DRAFT-toolchain-D5"
             (term-amendment (find-genre-status (find-genre "Plan") "Superseded"))))
  (is (eq :pending (genre-family-standing (find-genre "Glossary")))))

(test legacy-superseded
  (is (equal "PSYCHE-0002" (legacy-superseded-target "Superseded-by: PSYCHE-0002")))
  (is (null (legacy-superseded-target "Superseded"))))

(test subtypes-and-fields
  (is-true (find-subtype (find-genre "Guide") "howto"))
  (is (eq :pending (term-standing (find-subtype (find-genre "Eval") "threat-model"))))
  (is-true (field-spec-required-p (find-field-spec "title")))
  (is-true (field-spec-derivable-p (find-field-spec "authors")))
  (is (eq :memo (field-spec-register-kind (find-field-spec "memos"))))
  (is (eq :pending (field-spec-standing (find-field-spec "read-if"))))
  (is (eq :memo (register-kind-keyword (find-register-kind #\M)))))

(test language-tags
  (dolist (tag '("en" "no" "pt-BR" "zh-Hant-TW" "sr-Latn" "es-419" "x-private"
                 "de-CH-1901"))
    (is-true (well-formed-language-tag-p tag) "~a should be well formed" tag))
  (dolist (tag '("" "e" "english!" "en_US" "en-" "-en"))
    (is-false (well-formed-language-tag-p tag) "~a should be rejected" tag)))

(defun skill-vocabulary-text ()
  (read-text-file (merge-pathnames "skills/reference/vocabularies.md" (repository-root))))

(test vocabulary-matches-skills
  "Accepted vocabulary agrees with skills/reference/vocabularies.md (D20)."
  (let ((text (skill-vocabulary-text)))
    (dolist (genre (genres :standing :accepted))
      (is-true (search (format nil "| `~a` | `~a` | ~a |" (genre-name genre)
                               (genre-prefix genre) (genre-code genre))
                       text)
               "the skills' genre table lacks ~a" (genre-name genre)))
    (dolist (family '(:proposal :reference :memo))
      (dolist (term (statuses-in-family family))
        (when (eq (term-standing term) :accepted)
          (is-true (search (format nil "| `~a` |" (term-name term)) text)
                   "the skills' status tables lack ~a" (term-name term)))))
    (dolist (scope (scopes))
      (is-true (search (format nil "| `~a` |" (term-name scope)) text)))))

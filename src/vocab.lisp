;;;; vocab.lisp — Controlled vocabularies, register kinds, and the front-matter field schema
;;;;
;;;; Read-if: adding or accepting a genre, status, subtype, scope, register kind, or front-matter field
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D20
;;;; Invariant: every value carries a standing; a pending value names the decision that introduces it
;;;; Tests: tests/test-vocab.lisp

(in-package #:compass.vocab)

;;; Terms

(defstruct (term (:constructor %make-term))
  (name "" :type string)
  (standing :accepted :type (member :accepted :pending))
  (amendment nil))

(defun make-terms (specs)
  "Build terms from SPECS, each a name or (name :pending amendment)."
  (mapcar (lambda (spec)
            (if (consp spec)
                (destructuring-bind (name standing amendment) spec
                  (%make-term :name name :standing standing :amendment amendment))
                (%make-term :name spec)))
          specs))

(defun find-term (name terms)
  (find name terms :key #'term-name :test #'string=))

;;; Status families (§6)

(defparameter *status-families*
  (list
   (cons :proposal
         (make-terms '("Draft" "Proposed" "In-Review" "Accepted" "Implemented"
                       "Design-Record" "Deprecated"
                       ("Superseded" :pending "COMPASS-DRAFT-toolchain-D5")
                       "Rejected" "Withdrawn")))
   (cons :reference
         (make-terms '("Current" "Draft" "Deprecated")))
   (cons :memo
         (make-terms '("Draft" "Current" "Deprecated" "Superseded"))))
  "Status vocabularies by family. The memo family is accepted
(COMPASS-DRAFT-agent-workflow-D4).")

(defparameter +legacy-superseded-prefix+ "Superseded-by:"
  "The §6 status form `Superseded-by: <id>`, which COMPASS-DRAFT-toolchain-D5
replaces with `Superseded` plus the `superseded-by:` field.")

(defun legacy-superseded-target (status)
  "If STATUS is the §6 form `Superseded-by: <id>`, return the id."
  (and (stringp status)
       (starts-with-p +legacy-superseded-prefix+ status)
       (trim-whitespace (subseq status (length +legacy-superseded-prefix+)))))

(defun statuses-in-family (family)
  (cdr (assoc family *status-families*)))

(defun find-status-in-family (family name)
  (find-term name (statuses-in-family family)))

(defun family-description (family)
  (ecase family
    (:proposal "proposal and record genres")
    (:reference "reference genres")
    (:memo "the Memo genre")))

;;; Genres (§4)

(defstruct (genre (:constructor %make-genre))
  name prefix code family
  (family-standing :accepted) family-amendment
  subtypes spine
  (standing :accepted) amendment
  role)

(defparameter *genres*
  (flet ((g (name prefix code family role &key subtypes spine family-standing
                                             family-amendment)
           (%make-genre :name name :prefix prefix :code code :family family
                        :role role :subtypes (make-terms subtypes) :spine spine
                        :family-standing (or family-standing :accepted)
                        :family-amendment family-amendment)))
    (list
     (g "Survey" "Survey." "SU" :proposal
        "Exploratory \"should we?\"; aspirational, non-normative"
        :spine '("Motivation" "Honest Limits" "Relationship to Other Work"
                 "Open Questions"))
     (g "Eval" "Eval." "EV" :proposal
        "Evaluative analysis against a rubric"
        :subtypes '("prior-art" "comparison" "tradeoff"
                    ("threat-model" :pending "COMPASS-DRAFT-secure-development"))
        :spine '("Method" "The Shared Scenario" "The Rubric" "Synthesis"))
     (g "Architecture" "Arch." "AR" :proposal
        "Comprehensive design record; aspirational and normative"
        :spine '("Canonical Terms" "Thesis / Concerns" "Influences"
                 "Settled Decisions" "Open Questions" "Roadmap" "Appendices"))
     (g "Plan" "Plan." "PL" :proposal
        "Forward design plus roadmap for a buildable unit"
        :spine '("Problem" "Goals" "Settled Decisions" "Open Questions"
                 "Prior Art" "Roadmap"))
     (g "Log" "Log." "LG" :proposal
        "Engineering journal of work done and verified"
        :spine '("Problem" "Design Decisions" "Implementation" "Verification"
                 "Files" "Outstanding Work"))
     (g "Ref" "Ref." "RF" :reference
        "Reference manual for running software"
        :spine '("Project Structure"))
     (g "Memo" "Memo." "ME" :memo
        "Verified, present-tense properties of running software, as M-records"
        :spine '("Memos"))
     (g "Guide" "Guide." "GD" :reference
        "Task walkthrough or demonstration"
        :subtypes '("tutorial" "howto")
        :spine '("Prerequisites"))
     (g "Spec" "Spec." "SP" :reference
        "Normative contract for running software")
     (g "Glossary" "Glossary." "GL" :reference
        "Canonical terms and backronym registry"
        :family-standing :pending
        :family-amendment "COMPASS-DRAFT-toolchain-D12")
     (g "Ideation" "Ideation." "ID" :proposal
        "Curated foundational seed discussion (rare)"
        :family-standing :pending
        :family-amendment "COMPASS-DRAFT-toolchain-D12"))))

(defun genres (&key standing)
  (if standing
      (remove standing *genres* :key #'genre-standing :test-not #'eq)
      *genres*))

(defun find-genre (name)
  (and (stringp name) (find name *genres* :key #'genre-name :test #'string=)))

(defun find-genre-by-prefix (prefix)
  "The genre whose filename prefix, without its dot, is PREFIX (e.g. \"Arch\")."
  (and (stringp prefix)
       (find-if (lambda (g) (string= (string-right-trim "." (genre-prefix g)) prefix))
                *genres*)))

(defun genre-statuses (genre)
  (statuses-in-family (genre-family genre)))

(defun find-genre-status (genre name)
  (find-status-in-family (genre-family genre) name))

(defun find-subtype (genre name)
  (find-term name (genre-subtypes genre)))

;;; Scopes (§5)

(defparameter *scopes* (make-terms '("component" "project" "program")))

(defun scopes () *scopes*)

(defun find-scope (name)
  (and (stringp name) (find-term name *scopes*)))

;;; Register kinds (§8)

(defstruct (register-kind (:constructor %make-register-kind))
  keyword letter field family label required-fields)

(defparameter *register-kinds*
  (list (%make-register-kind :keyword :decision :letter #\D :field "decisions"
                             :family :proposal :label "Decision"
                             :required-fields '("Status"))
        (%make-register-kind :keyword :open-question :letter #\O
                             :field "open-questions" :family nil
                             :label "Open question" :required-fields '())
        (%make-register-kind :keyword :memo :letter #\M :field "memos"
                             :family :memo :label "Memo"
                             :required-fields '("Status" "Read-if" "Basis"))))

(defun register-kinds () *register-kinds*)

(defun find-register-kind (designator)
  "Find a register kind by keyword, letter, or front-matter field name."
  (find-if (lambda (k)
             (etypecase designator
               (keyword (eq designator (register-kind-keyword k)))
               (character (char= designator (register-kind-letter k)))
               (string (string= designator (register-kind-field k)))))
           *register-kinds*))

;;; Front-matter fields (§7)

(defstruct (field-spec (:constructor %make-field-spec))
  name type required-p derivable-p genres extension-p
  (standing :accepted) amendment register-kind)

(defparameter *field-specs*
  (flet ((f (name type &key required derivable genres extension
                         (standing :accepted) amendment register-kind)
           (%make-field-spec :name name :type type :required-p required
                             :derivable-p derivable :genres genres
                             :extension-p extension :standing standing
                             :amendment amendment :register-kind register-kind)))
    (list
     (f "id" :identifier :required t)
     (f "title" :line :required t)
     (f "genre" :vocabulary :required t)
     (f "subtype" :vocabulary)
     (f "scope" :vocabulary :required t)
     (f "program" :string)
     (f "project" :string)
     (f "component" :string)
     (f "language" :language :required t)
     (f "status" :vocabulary :required t)
     (f "api-version" :string :genres '("Ref" "Guide"))
     (f "schema-version" :string :genres '("Spec"))
     (f "created" :date :required t :derivable t)
     (f "updated" :date :derivable t)
     (f "authors" :string-list :required t :derivable t)
     (f "reviewers" :string-list)
     (f "approved-by" :string)
     (f "reviewed" :date)
     (f "provenance" :provenance)
     (f "supersedes" :identifier-or-list)
     (f "superseded-by" :identifier)
     (f "relates-to" :identifiers)
     (f "cites" :cites)
     (f "decisions" :registers :register-kind :decision)
     (f "open-questions" :registers :register-kind :open-question)
     (f "memos" :registers :register-kind :memo :genres '("Memo"))
     (f "glossary" :string)
     (f "read-if" :line :extension t :standing :pending
                         :amendment "COMPASS-DRAFT-toolchain-D13"))))

(defun field-specs () *field-specs*)

(defun find-field-spec (name)
  (find name *field-specs* :key #'field-spec-name :test #'string=))

;;; Values

(defun true-string-p (string)
  "True for the YAML spellings of true accepted in `external:`."
  (and (stringp string) (member string '("true" "True" "TRUE") :test #'string=) t))

(defparameter *language-tag-scanner*
  (ppcre:create-scanner
   "^(?:(?:[A-Za-z]{2,3}(?:-[A-Za-z]{3}){0,3}|[A-Za-z]{4}|[A-Za-z]{5,8})(?:-[A-Za-z]{4})?(?:-(?:[A-Za-z]{2}|[0-9]{3}))?(?:-(?:[A-Za-z0-9]{5,8}|[0-9][A-Za-z0-9]{3}))*(?:-[0-9A-WY-Za-wy-z](?:-[A-Za-z0-9]{2,8})+)*(?:-[xX](?:-[A-Za-z0-9]{1,8})+)?|[xX](?:-[A-Za-z0-9]{1,8})+)$"))

(defun well-formed-language-tag-p (string)
  "True if STRING is a well-formed BCP 47 language tag."
  (and (stringp string) (ppcre:scan *language-tag-scanner* string) t))

;;; Files that are never Compass documents (COMPASS-DRAFT-toolchain-D10)

(defparameter *non-document-names* '("README.md" "INDEX.md" "CATALOG.md" "MAP.md"))

(defun non-document-file-p (file-name)
  (and (member file-name *non-document-names* :test #'string=) t))

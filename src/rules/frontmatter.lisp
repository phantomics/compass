;;;; frontmatter.lisp — Rules for front-matter fields, their types, and controlled vocabularies
;;;;
;;;; Read-if: changing a front-matter or vocabulary rule
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D5, COMPASS-DRAFT-toolchain-D20
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.rules)

(defun front-matter-start (document)
  "The line of the opening --- of DOCUMENT's front-matter."
  (declare (ignore document))
  1)

(defun field-entry (document key)
  (yaml-get-entry (document-front-matter document) key))

(define-rule "fm/required" (:severity :error :section "§7"
                            :summary "Required front-matter fields are present")
    (document corpus)
  (declare (ignore corpus))
  (dolist (spec (field-specs))
    ;; Git-derivable fields are checked by git/derivable.
    (when (and (field-spec-required-p spec) (not (field-spec-derivable-p spec))
               (yaml-null-p (document-field-node document (field-spec-name spec))))
      (emit document (front-matter-start document)
            "missing required field `~a`" (field-spec-name spec)))))

(define-rule "git/derivable" (:severity :error :section "§7"
                              :summary "Required fields left out of front-matter can be ~
                                        derived from Git")
    (document corpus)
  (let ((missing (loop for spec in (field-specs)
                       when (and (field-spec-required-p spec) (field-spec-derivable-p spec)
                                 (yaml-null-p (document-field-node document
                                                                   (field-spec-name spec))))
                         collect (field-spec-name spec))))
    (when missing
      (if (not (git-available-p))
          (note corpus "git/derivable did not run: Git was not found")
          (multiple-value-bind (reason identity-p) (underivable-reason corpus document)
            (when reason
              (emit document (front-matter-start document)
                    "~{`~a`~^ and ~} ~:[is~;are~] not in front-matter and cannot be derived ~
                     from Git, because ~a; ~:[~;set a name with git config user.name, or ~
                     ~]write ~:[it~;them~] in front-matter"
                    missing (rest missing) reason identity-p (rest missing))))))))

(define-rule "fm/types" (:severity :error :section "§7"
                         :summary "Front-matter values have the types the schema requires")
    (document corpus)
  (declare (ignore corpus))
  (dolist (entry (yaml-mapping-entries (document-front-matter document)))
    (let ((spec (find-field-spec (yaml-entry-key entry))))
      (when spec
        (multiple-value-bind (value problems) (convert-field spec (yaml-entry-value entry))
          (declare (ignore value))
          (dolist (problem problems)
            (destructuring-bind (where severity message) problem
              (emit-severity severity document (or where entry) "~a" message))))
        (when (and (string= (field-spec-name spec) "glossary")
                   (node-string (yaml-entry-value entry))
                   (not (parse-identifier (node-string (yaml-entry-value entry)))))
          (emit-severity :warning document (yaml-entry-value entry)
                         "`glossary` should name the glossary by its identifier; ~s is a ~
                          document name" (node-string (yaml-entry-value entry))))))))

(define-rule "fm/language" (:severity :error :section "§7, §12"
                            :summary "`language` is a well-formed BCP 47 tag")
    (document corpus)
  (declare (ignore corpus))
  (let* ((node (document-field-node document "language"))
         (value (node-string node)))
    (when (and value (not (well-formed-language-tag-p value)))
      (emit document node "`language` value ~s is not a BCP 47 language tag, such as en ~
                           or pt-BR" value))))

(define-rule "fm/unknown-key" (:severity :warning :section "§18"
                               :summary "Every front-matter key is a core field or a ~
                                         registered extension")
    (document corpus)
  (declare (ignore corpus))
  (dolist (entry (yaml-mapping-entries (document-front-matter document)))
    (let ((key (yaml-entry-key entry)))
      (unless (find-field-spec key)
        (let ((suggestion (closest-match key (mapcar #'field-spec-name (field-specs)))))
          (emit document entry "unrecognised front-matter key `~a`~@[; did you mean `~a`?~]"
                key suggestion))))))

;;; Vocabularies

(defun vocabulary-entry (document key)
  "The entry and string value of the scalar field KEY, or NIL."
  (let ((entry (field-entry document key)))
    (and entry (node-string (yaml-entry-value entry))
         (values entry (node-string (yaml-entry-value entry))))))

(defun document-genre-object (document)
  (find-genre (document-genre document)))

(defun quoted-list (names)
  (format nil "~{~a~^, ~}" names))

(define-rule "vocab/genre" (:severity :error :section "§4"
                            :summary "`genre` is one of the controlled genres")
    (document corpus)
  (declare (ignore corpus))
  (multiple-value-bind (entry genre) (vocabulary-entry document "genre")
    (when (and entry (not (find-genre genre)))
      (let ((by-prefix (find-genre-by-prefix genre))
            (near (closest-match genre (mapcar #'genre-name (genres)))))
        (let ((hint (cond (by-prefix (genre-name by-prefix)) (near near))))
          (if hint
              (emit document (yaml-entry-value entry)
                    "unknown genre ~s; did you mean ~a?" genre hint)
              (emit document (yaml-entry-value entry)
                    "unknown genre ~s; the genres are ~a" genre
                    (quoted-list (mapcar #'genre-name (genres))))))))))

(define-rule "vocab/subtype" (:severity :error :section "§4"
                              :summary "`subtype` is valid for the genre")
    (document corpus)
  (declare (ignore corpus))
  (let ((genre (document-genre-object document)))
    (when genre
      (multiple-value-bind (entry subtype) (vocabulary-entry document "subtype")
        (cond
          ((and entry (null (genre-subtypes genre)))
           (emit document entry "~a documents take no subtype" (genre-name genre)))
          ((and entry (not (find-subtype genre subtype)))
           (emit document (yaml-entry-value entry)
                 "unknown ~a subtype ~s; the subtypes are ~a" (genre-name genre) subtype
                 (quoted-list (mapcar #'term-name (genre-subtypes genre)))))
          ((and (null entry) (genre-subtypes genre))
           (emit-severity :warning document (front-matter-start document)
                          "~a documents carry a subtype (~a)" (genre-name genre)
                          (quoted-list (mapcar #'term-name (genre-subtypes genre))))))))))

(define-rule "vocab/scope" (:severity :error :section "§5"
                            :summary "`scope` is component, project, or program")
    (document corpus)
  (declare (ignore corpus))
  (multiple-value-bind (entry scope) (vocabulary-entry document "scope")
    (when (and entry (not (find-scope scope)))
      (emit document (yaml-entry-value entry)
            "unknown scope ~s; the scopes are component, project, and program" scope))))

(define-rule "vocab/status" (:severity :error :section "§6"
                             :summary "`status` is in the genre's status vocabulary")
    (document corpus)
  (declare (ignore corpus))
  (let ((genre (document-genre-object document)))
    (multiple-value-bind (entry status) (vocabulary-entry document "status")
      (when (and genre entry)
        (cond
          ((find-genre-status genre status))
          ((and (legacy-superseded-target status) (eq (genre-family genre) :proposal))
           (emit-severity :warning document (yaml-entry-value entry)
                          "the §6 form `Superseded-by: <id>` cannot be written unquoted ~
                           in YAML; COMPASS-DRAFT-toolchain-D5 proposes `status: ~
                           Superseded` with the successor in `superseded-by:`"))
          (t
           (emit document (yaml-entry-value entry)
                 "~s is not a status of ~a; ~a documents use ~a" status
                 (family-description (genre-family genre)) (genre-name genre)
                 (quoted-list (mapcar #'term-name (genre-statuses genre))))))))))

(defun note-pending (document where what term)
  (when (and term (eq (term-standing term) :pending))
    (emit document where "~a is pending: it is introduced by ~a, which has not been ~
                          accepted" what (term-amendment term))))

(define-rule "vocab/pending" (:severity :warning :section "§13"
                              :summary "No vocabulary value or field is pending acceptance")
    (document corpus)
  (declare (ignore corpus))
  (let ((genre (document-genre-object document)))
    (when genre
      (when (eq (genre-family-standing genre) :pending)
        (multiple-value-bind (entry) (vocabulary-entry document "status")
          (emit document (if entry (yaml-entry-value entry) 1)
                "the status vocabulary of ~a documents is pending: it is introduced by ~
                 ~a, which has not been accepted"
                (genre-name genre) (genre-family-amendment genre))))
      (multiple-value-bind (entry status) (vocabulary-entry document "status")
        (when entry
          (note-pending document (yaml-entry-value entry) (format nil "Status ~s" status)
                        (find-genre-status genre status))))
      (multiple-value-bind (entry subtype) (vocabulary-entry document "subtype")
        (when entry
          (note-pending document (yaml-entry-value entry) (format nil "Subtype ~s" subtype)
                        (find-subtype genre subtype))))))
  (dolist (entry (yaml-mapping-entries (document-front-matter document)))
    (let ((spec (find-field-spec (yaml-entry-key entry))))
      (when (and spec (eq (field-spec-standing spec) :pending))
        (emit document entry "the field `~a` is pending: it is introduced by ~a, which ~
                              has not been accepted"
              (field-spec-name spec) (field-spec-amendment spec)))))
  (dolist (record (document-records document))
    (let ((kind (find-register-kind (record-kind record)))
          (status (record-field record "Status")))
      (when (and status (register-kind-family kind))
        (note-pending document (or (record-field-entry record "Status") record)
                      (format nil "Status ~s of ~a" status (record-id record))
                      (find-status-in-family (register-kind-family kind) status))))))

(define-rule "status/superseded-agrees" (:severity :error :section "§6, §7"
                                         :summary "`Superseded` and `superseded-by` ~
                                                   appear together")
    (document corpus)
  (declare (ignore corpus))
  (multiple-value-bind (status-entry status) (vocabulary-entry document "status")
    (let* ((successor-entry (field-entry document "superseded-by"))
           (successor (and successor-entry (node-string (yaml-entry-value successor-entry))))
           (legacy (legacy-superseded-target status)))
      (cond
        ((and status (string= status "Superseded") (null successor))
         (emit document (yaml-entry-value status-entry)
               "status `Superseded` requires `superseded-by:` naming the successor"))
        ((and successor (not (or legacy (and status (string= status "Superseded")))))
         (emit document successor-entry
               "`superseded-by:` requires status `Superseded`~@[, not ~s~]" status))
        ((and legacy successor (string/= legacy successor))
         (emit document successor-entry
               "`superseded-by:` names ~a, but the status names ~a" successor legacy))))))

(define-rule "cite/well-formed" (:severity :error :section "§9"
                                 :summary "Each `cites` entry has a title, a locator, and ~
                                           `external: true`")
    (document corpus)
  (declare (ignore corpus))
  (let ((cites (document-field-node document "cites")))
    (when (yaml-sequence-p cites)
      (dolist (item (yaml-sequence-items cites))
        (when (yaml-mapping-p item)
          (dolist (key '("title" "locator"))
            (let ((value (yaml-get item key)))
              (unless (and (node-string value) (not (blank-string-p (node-string value))))
                (emit document item "a `cites` entry needs a non-empty `~a`" key))))
          (let ((external (yaml-get item "external")))
            (cond ((yaml-null-p external)
                   (emit document item "a `cites` entry needs `external: true`; ~
                                        references within the corpus go in `relates-to`"))
                  ((not (true-string-p (node-string external)))
                   (emit document external "`external` must be true; references within ~
                                            the corpus go in `relates-to`"))))
          (dolist (entry (yaml-mapping-entries item))
            (unless (member (yaml-entry-key entry) '("title" "locator" "external")
                            :test #'string=)
              (emit-severity :warning document entry
                             "unrecognised key `~a` in a `cites` entry"
                             (yaml-entry-key entry)))))))))

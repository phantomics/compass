;;;; packages.lisp — Package definitions for the layered Compass toolchain
;;;;
;;;; Read-if: adding an exported symbol, or a package
;;;; See: COMPASS-DRAFT-toolchain-D21
;;;; Invariant: a package uses only the packages defined above it in this file

(defpackage #:compass.util
  (:use #:cl)
  (:export #:read-text-file #:write-text-file
           #:text-file-error #:text-file-error-pathname #:text-file-error-reason
           #:split-lines #:join-lines #:string-join #:first-difference
           #:trim-whitespace #:blank-string-p #:starts-with-p #:ends-with-p
           #:edit-distance #:closest-match
           #:valid-date-string-p
           #:relative-path-string #:normalize-relative-path #:percent-decode
           #:file-kind #:root-file #:babel-free-encode #:babel-free-decode))

(defpackage #:compass.git
  (:use #:cl #:compass.util)
  (:export #:*git-program* #:git-unavailable #:git-unavailable-program
           #:git-error #:git-error-arguments #:git-error-status #:git-error-output
           #:run-git #:git-available-p #:git-repository-p #:git-resolve
           #:git-has-commits-p #:git-object-type #:git-file-at #:git-shallow-p
           #:git-attribute #:git-tracked-files #:git-added-lines #:git-identity
           #:*default-bases* #:git-default-base
           #:git-object-types #:git-read-objects #:git-log-follow #:git-file-status
           #:git-committed-files))

(defpackage #:compass.vocab
  (:use #:cl #:compass.util)
  (:export #:term #:term-name #:term-standing #:term-amendment
           #:genre #:genre-name #:genre-prefix #:genre-code #:genre-family
           #:genre-family-standing #:genre-family-amendment #:genre-subtypes
           #:genre-spine #:genre-standing #:genre-amendment #:genre-role
           #:genres #:find-genre #:find-genre-by-prefix #:genre-statuses
           #:find-genre-status #:find-subtype
           #:statuses-in-family #:find-status-in-family #:family-description
           #:scopes #:find-scope
           #:register-kind #:register-kind-keyword #:register-kind-letter
           #:register-kind-field #:register-kind-family #:register-kind-label
           #:register-kind-required-fields
           #:register-kinds #:find-register-kind
           #:field-spec #:field-spec-name #:field-spec-type #:field-spec-required-p
           #:field-spec-derivable-p #:field-spec-genres #:field-spec-extension-p
           #:field-spec-standing #:field-spec-amendment #:field-spec-register-kind
           #:field-specs #:find-field-spec
           #:well-formed-language-tag-p
           #:+legacy-superseded-prefix+ #:legacy-superseded-target
           #:non-document-file-p #:true-string-p))

(defpackage #:compass.model
  (:use #:cl #:compass.util #:compass.vocab)
  (:export
   ;; identifiers
   #:identifier #:identifier-string #:identifier-namespace #:identifier-kind
   #:identifier-serial #:identifier-slug #:identifier-provisional-p
   #:identifier-host #:parse-identifier #:identifier-document-p
   #:identifier-register-p #:diagnose-identifier #:format-canonical-identifier
   #:split-reference #:find-identifiers-in-text #:replace-identifiers-in-text
   #:*identifier-in-text-scanner*
   ;; restricted s-expression reader
   #:read-restricted-sexps #:sexp-syntax-error #:sexp-syntax-error-message
   #:sexp-syntax-error-line #:sexp-syntax-error-column
   #:foreign-keyword #:foreign-keyword-p #:foreign-keyword-name
   ;; YAML nodes
   #:yaml-node #:yaml-node-line #:yaml-node-column
   #:yaml-scalar #:make-yaml-scalar #:yaml-scalar-p #:yaml-scalar-value
   #:yaml-scalar-style #:yaml-null-p
   #:yaml-sequence #:make-yaml-sequence #:yaml-sequence-p #:yaml-sequence-items
   #:yaml-mapping #:make-yaml-mapping #:yaml-mapping-p #:yaml-mapping-entries
   #:yaml-entry #:make-yaml-entry #:yaml-entry-key #:yaml-entry-line
   #:yaml-entry-column #:yaml-entry-value #:yaml-get #:yaml-get-entry
   ;; document model
   #:located #:location-line #:location-column
   #:section #:section-level #:section-text #:section-anchor #:section-parent
   #:section-end-line
   #:register-record #:record-id #:record-identifier #:record-kind #:record-title
   #:record-short-form-p #:record-separator #:record-level #:record-fields
   #:record-field #:record-field-entry #:record-end-line #:record-document
   #:field-entry #:make-field-entry #:field-entry-label #:field-entry-value
   #:field-entry-line
   #:link #:link-text #:link-target #:link-image-p
   #:table-block #:table-caption #:table-caption-line #:table-header-cells
   #:table-end-line
   #:fence #:fence-info #:fence-end-line #:fence-closed-p
   #:code-span #:code-span-text
   #:document #:document-path #:document-pathname #:document-text
   #:document-lines #:document-front-matter #:document-has-front-matter-p
   #:document-front-matter-valid-p #:document-body-start-line
   #:document-sections #:document-records #:document-links #:document-images
   #:document-tables #:document-fences #:document-code-spans
   #:document-load-findings
   #:document-field #:document-field-node #:document-field-string
   #:document-id #:document-identifier #:document-genre #:document-status
   #:document-title #:document-scope #:document-namespace #:document-component
   #:document-anchors #:document-record
   #:finding #:make-finding #:finding-rule #:finding-severity #:finding-path
   #:finding-line #:finding-column #:finding-message
   ;; typed fields
   #:convert-field #:node-string #:node-identifiers
   ;; manifest
   #:manifest #:manifest-path #:manifest-namespaces #:manifest-doc-directory
   #:manifest-federation #:manifest-stewards #:manifest-commands
   #:manifest-map #:manifest-catalog #:manifest-authorities
   #:manifest-command #:manifest-command-name #:command-kind #:command-text
   #:command-doc
   #:federation-entry #:federation-entry-namespace #:federation-entry-path
   #:steward-entry #:steward-namespace #:steward-name #:steward-approval
   #:read-manifest #:default-manifest #:+manifest-file-name+ #:manifest-text
   ;; ledger
   #:+ledger-file-name+ #:ledger-entry #:make-ledger-entry #:copy-ledger-entry
   #:ledger-entry-id #:ledger-entry-identifier #:ledger-entry-kind
   #:ledger-entry-draft #:ledger-entry-path #:ledger-entry-host
   #:ledger-entry-date #:ledger-entry-by #:ledger-entry-line #:ledger-entry-text
   #:ledger #:make-ledger #:ledger-path #:ledger-text #:ledger-entries
   #:ledger-by-id #:ledger-by-alias
   #:ledger-entry-for #:ledger-alias-entry #:ledger-aliases-of
   #:ledger-namespace-entries #:*ledger-kinds*
   #:conflict-marker-p #:ledger-ignorable-line-p #:parse-ledger-line
   #:parse-ledger-text #:read-ledger #:format-ledger-entry #:ledger-header
   #:ledger-text-with-entries #:today))

(defpackage #:compass.parse
  (:use #:cl #:compass.util #:compass.vocab #:compass.model)
  (:export #:front-matter-syntax-error #:front-matter-syntax-error-line
           #:front-matter-syntax-error-column #:front-matter-syntax-error-message
           #:split-front-matter #:parse-front-matter #:parse-yaml-subset
           #:find-code-spans #:strip-inline-markup #:heading-anchor #:slugify
           #:parse-code-reference #:code-reference #:code-reference-namespace
           #:code-reference-path #:code-reference-symbol
           #:code-reference-line-start #:code-reference-line-end
           #:code-reference-revision
           #:body #:scan-body #:body-sections #:body-records #:body-links
           #:body-images #:body-tables #:body-fences #:body-code-spans
           #:read-document #:parse-document #:document-line-kinds
           #:find-inline-comments))

(defpackage #:compass.corpus
  (:use #:cl #:compass.util #:compass.git #:compass.vocab #:compass.model
        #:compass.parse)
  (:export #:corpus #:corpus-root #:corpus-manifest #:corpus-documents
           #:corpus-skipped #:corpus-load-findings #:corpus-unverified
           #:corpus-doc-directory #:corpus-namespaces
           #:find-repository-root #:load-corpus
           #:corpus-ledger #:corpus-ledger-path #:corpus-notes #:note
           #:corpus-alias-target #:corpus-names-of #:corpus-owned-namespace-p
           #:corpus-ledger-pathname #:canonical-definitions #:provisional-definitions
           #:allocation #:allocation-command #:allocation-mapping #:allocation-entries
           #:allocation-ledger-text #:allocation-rewrites #:allocation-stale
           #:allocation-warnings #:allocation-base #:allocation-document
           #:allocation-refused #:allocation-refused-message
           #:plan-assign #:plan-renumber #:plan-seed #:execute-allocation
           #:strip-conflict-markers
           #:rewrite #:rewrite-path #:rewrite-old-text #:rewrite-new-text
           #:rewrite-changed-lines #:plan-rewrites #:rewrite-line
           #:used-serials #:next-provisional-record #:base-ledger-entries
           #:+accepted-statuses+
           #:short-reference #:short-reference-line #:short-reference-column
           #:short-reference-text #:short-reference-suggestion
           #:short-reference-written #:document-short-references
           #:short-references-to #:line-short-references
           #:find-document #:find-documents #:find-record #:find-records
           #:resolve #:namespace-loaded-p #:note-unverified
           #:markdown-anchors #:document-at-path #:corpus-paths #:corpus-empty-p
           #:link-destination #:path-directory #:record-anchor
           #:outline #:outline-id #:outline-path #:outline-title #:outline-genre
           #:outline-status #:outline-total-lines #:outline-front-matter-end
           #:outline-focus #:outline-record #:outline-entries
           #:outline-entry #:outline-entry-level #:outline-entry-text
           #:outline-entry-anchor #:outline-entry-start #:outline-entry-end
           #:outline-entry-record #:outline-alias #:outline-fields #:document-outline
           #:inbound-reference #:inbound-reference-kind #:inbound-reference-path
           #:inbound-reference-line #:inbound-reference-column
           #:inbound-reference-field #:inbound-reference-text
           #:inbound-reference-source #:inbound-reference-name #:find-references
           #:show
           #:generate-index #:write-index #:index-relative-path
           #:next-identifier #:refuse
           #:corpus-cache #:corpus-cached
           #:repository-usable-p #:git-state #:corpus-git-state #:git-state-usable #:git-state-reason
           #:git-state-identity #:git-state-shallow #:document-committed-p
           #:underivable-reason #:derived-field #:derived-field-name
           #:derived-field-value #:derived-field-source #:derived-field-note
           #:document-derived-fields
           #:code-mention #:code-mention-document #:code-mention-span #:code-mention-text
           #:code-mention-namespace #:code-mention-path #:code-mention-symbol
           #:code-mention-line-start #:code-mention-line-end #:code-mention-line
           #:code-mention-revision #:code-mention-basis-p #:parse-code-mention
           #:document-code-mentions #:resolve-code-mentions #:revision-status
           #:symbol-defined-p
           #:federated #:federated-entry #:federated-root #:federated-manifest
           #:federated-corpus #:federated-problem #:corpus-federation
           #:corpus-federation-loaded-p #:federated-corpora #:load-federation
           #:namespace-root #:federated-location))

(defpackage #:compass.rules
  (:use #:cl #:compass.util #:compass.git #:compass.vocab #:compass.model
        #:compass.parse #:compass.corpus)
  (:export #:define-rule #:rule #:rule-name #:rule-severity #:rule-section
           #:rule-scope #:rule-summary #:find-rule #:list-rules
           #:emit #:emit-severity #:unverified #:run-rules #:check-corpus
           #:rule-selected-p #:*check-base*))

(defpackage #:compass.report
  (:use #:cl #:compass.util #:compass.model #:compass.corpus #:compass.rules)
  (:export #:write-findings #:summarize #:exit-code #:sort-findings))

(defpackage #:compass.cli
  (:use #:cl #:compass.util #:compass.git #:compass.vocab #:compass.model
        #:compass.parse #:compass.corpus #:compass.rules #:compass.report)
  (:export #:main #:*build-commit* #:+version+ #:command-names
           #:command-option-names))

(uiop:define-package #:compass
  (:use #:cl)
  (:use-reexport #:compass.util #:compass.git #:compass.vocab #:compass.model #:compass.parse
                 #:compass.corpus #:compass.rules #:compass.report #:compass.cli))

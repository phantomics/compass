;;;; references.lisp — Rules for references between documents
;;;;
;;;; Read-if: changing how identifiers in front-matter or links in the body are resolved
;;;; See: COMPASS-0001, COMPASS-DRAFT-toolchain-D21
;;;; Invariant: references into namespaces that are not loaded are unverified, not errors
;;;; Tests: tests/test-rules.lisp

(in-package #:compass.rules)

(defparameter *url-scheme-scanner* (ppcre:create-scanner "^[A-Za-z][A-Za-z0-9+.-]*:"))

(defun external-target-p (target)
  (or (ppcre:scan *url-scheme-scanner* target) (starts-with-p "//" target)))

(defun directory-of (path)
  (let ((slash (position #\/ path :from-end t)))
    (if slash (subseq path 0 (1+ slash)) "")))

(defun check-identifier-reference (document corpus node id field)
  (let ((parsed (parse-identifier id)))
    (when parsed
      (cond ((not (namespace-loaded-p corpus (identifier-namespace parsed)))
             (unverified document node id))
            ((or (find-document corpus id) (find-record corpus id)))
            (t (emit document node "`~a` names ~a, which is not defined in the corpus"
                     field id))))))

(defun check-front-matter-references (document corpus)
  (dolist (field '("relates-to" "supersedes" "superseded-by" "glossary"))
    (let ((node (document-field-node document field)))
      (cond ((yaml-scalar-p node)
             (let ((id (node-string node)))
               (when id (check-identifier-reference document corpus node id field))))
            ((yaml-sequence-p node)
             (dolist (item (yaml-sequence-items node))
               (let ((id (node-string item)))
                 (when id (check-identifier-reference document corpus item id field)))))))))

(defun check-link-text (document corpus link target-path target-document)
  "If LINK's text is an identifier, check that the target declares or defines it."
  (declare (ignore corpus))
  (let* ((text (trim-whitespace (strip-inline-markup (link-text link))))
         (id (parse-identifier text)))
    (when id
      (cond
        ((or (null target-document) (not (document-has-front-matter-p target-document)))
         (when (ends-with-p ".md" target-path)
           (emit document link "the link text names ~a, but ~a has no front-matter"
                 text target-path)))
        ((identifier-document-p id)
         (unless (equal (document-id target-document) text)
           (emit document link "the link text names ~a, but ~a declares ~:[no id~;~:*~a~]"
                 text target-path (document-id target-document))))
        ((not (document-record target-document text))
         (emit document link "the link text names record ~a, which ~a does not define"
               text target-path))))))

(defun check-link (document corpus link)
  (let ((target (link-target link)))
    (unless (or (string= target "") (external-target-p target))
      (let* ((hash (position #\# target))
             (path-part (percent-decode (subseq target 0 hash)))
             (fragment (and hash (subseq target (1+ hash)))))
        (if (string= path-part "")
            (progn
              (when (and fragment (plusp (length fragment))
                         (not (member fragment (document-anchors document) :test #'string=)))
                (emit document link "no heading in this document has the anchor #~a" fragment))
              (unless (link-image-p link)
                (check-link-text document corpus link (document-path document) document)))
            (multiple-value-bind (path escapes)
                (normalize-relative-path (directory-of (document-path document)) path-part)
              (if escapes
                  (unverified document link target)
                  (let ((kind (file-kind (corpus-root corpus) path)))
                    (cond
                      ((null kind)
                       (emit document link "the link target ~a does not exist" path-part))
                      ((and fragment (plusp (length fragment)) (eq kind :file)
                            (ends-with-p ".md" (string-downcase path))
                            (not (member fragment (markdown-anchors corpus path)
                                         :test #'string=)))
                       (emit document link "~a has no heading with the anchor #~a"
                             path-part fragment)))
                    (when (and kind (not (link-image-p link)))
                      (check-link-text document corpus link path
                                       (document-at-path corpus path)))))))))))

(define-rule "ref/doc-resolves" (:severity :error :section "§9" :front-matter nil
                                 :summary "Document references and links resolve")
    (document corpus)
  (when (document-front-matter document)
    (check-front-matter-references document corpus))
  (dolist (link (append (document-links document) (document-images document)))
    (check-link document corpus link)))

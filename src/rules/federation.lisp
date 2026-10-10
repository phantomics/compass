;;;; federation.lisp — Rules for the federated repositories, and for the generated index
;;;;
;;;; Read-if: changing what --federation reports, or how a stale INDEX.md is found
;;;; See: COMPASS-DRAFT-toolchain-D4, COMPASS-DRAFT-toolchain-D6, COMPASS-DRAFT-toolchain-D29
;;;; Invariant: the federation rules run only when --federation loaded the federation
;;;; Tests: tests/test-federation.lisp

(in-package #:compass.rules)

(defun manifest-entry-line (corpus entry)
  "The line of compass.sexp that gives ENTRY's path, or 1."
  (let* ((pathname (manifest-path (corpus-manifest corpus)))
         (text (and pathname (uiop:file-exists-p pathname)
                    (ignore-errors (read-text-file pathname))))
         (needle (format nil "\"~a\"" (federation-entry-path entry))))
    (or (and text
             (loop for line across (split-lines text)
                   for n from 1
                   when (search needle line) return n))
        1)))

(defun manifest-file-path (corpus)
  (declare (ignore corpus))
  +manifest-file-name+)

(define-rule "federation/path" (:severity :error :scope :corpus :section "§5"
                                :summary "Each federated repository exists, has a manifest, ~
                                          and owns the namespace it is listed for (with ~
                                          --federation)")
    (corpus)
  (when (corpus-federation-loaded-p corpus)
    (dolist (f (corpus-federation corpus))
      (let* ((entry (federated-entry f))
             (path (federation-entry-path entry))
             (namespace (federation-entry-namespace entry))
             (where (manifest-entry-line corpus entry)))
        (case (federated-problem f)
          (:missing
           (emit (manifest-file-path corpus) where
                 "the federated repository for ~a, ~a, does not exist" namespace path))
          (:no-manifest
           (emit (manifest-file-path corpus) where
                 "the federated repository ~a has no compass.sexp, so it cannot be ~
                  shown to own ~a" path namespace))
          (:not-owned
           (emit (manifest-file-path corpus) where
                 "~a is listed for ~a, but its compass.sexp owns ~:[no namespace~;~:*~{~a~^, ~}~]"
                 path namespace (manifest-namespaces (federated-manifest f)))))))))

(define-rule "federation/namespace" (:severity :error :scope :corpus :section "§5, §13"
                                     :summary "No namespace is owned by two repositories of ~
                                               the federation (with --federation)")
    (corpus)
  (when (corpus-federation-loaded-p corpus)
    (let ((own (manifest-namespaces (corpus-manifest corpus)))
          (others (remove nil (corpus-federation corpus) :key #'federated-manifest)))
      (loop for (f . rest) on others
            for namespaces = (manifest-namespaces (federated-manifest f))
            for path = (federation-entry-path (federated-entry f))
            do (dolist (ns (intersection own namespaces :test #'string=))
                 (emit (manifest-file-path corpus) (manifest-entry-line corpus (federated-entry f))
                       "~a is owned both by this repository and by ~a; a namespace is minted ~
                        by one repository" ns path))
               (dolist (g rest)
                 (dolist (ns (intersection namespaces (manifest-namespaces (federated-manifest g))
                                           :test #'string=))
                   (emit (manifest-file-path corpus)
                         (manifest-entry-line corpus (federated-entry g))
                         "~a is owned by both ~a and ~a; a namespace is minted by one repository"
                         ns path (federation-entry-path (federated-entry g)))))))))

;;; The generated index (D6)

(defun index-difference (corpus)
  "If INDEX.md exists and differs from what compass index would write, the first
line that differs; otherwise NIL."
  (let ((pathname (root-file (corpus-root corpus) (index-relative-path corpus))))
    (when (uiop:file-exists-p pathname)
      (let ((written (handler-case (read-text-file pathname) (text-file-error () "")))
            (expected (generate-index corpus)))
        (let ((a (split-lines written)) (b (split-lines expected)))
          (unless (and (= (length a) (length b)) (every #'string= a b))
            (first-difference written expected)))))))

(define-rule "index/current" (:severity :error :scope :corpus :section "§13"
                              :summary "The generated INDEX.md matches the documents")
    (corpus)
  (let ((line (index-difference corpus)))
    (when line
      (emit (index-relative-path corpus) line
            "~a differs from what compass index would write, from this line; ~
             regenerate it with compass index" (index-relative-path corpus)))))

;;;; federation.lisp — Loading the repositories a manifest federates with, one hop deep
;;;;
;;;; Read-if: changing what --federation loads, or how a reference into another repository resolves
;;;; See: COMPASS-DRAFT-toolchain-D4, COMPASS-DRAFT-toolchain-D29
;;;; Invariant: federated repositories' own :federation lists are never followed
;;;; Invariant: federated documents resolve references; they are never checked themselves
;;;; Tests: tests/test-federation.lisp

(in-package #:compass.corpus)

(defun federation-directory (corpus entry)
  "The directory ENTRY's path names, relative to CORPUS's root, or NIL if there
is none."
  (let ((path (federation-entry-path entry)))
    (and (stringp path) (plusp (length path))
         (uiop:directory-exists-p
          (uiop:merge-pathnames* (uiop:parse-unix-namestring path :ensure-directory t)
                                 (corpus-root corpus))))))

(defun load-federation (corpus)
  "Load the repositories CORPUS's manifest federates with (D29): each one's
manifest, documents (skipping files without front-matter), and ledger. Return
CORPUS."
  (setf (corpus-federation corpus)
        (loop for entry in (manifest-federation (corpus-manifest corpus))
              collect
              (let ((root (federation-directory corpus entry)))
                (cond
                  ((null root) (make-federated :entry entry :problem :missing))
                  ((not (uiop:file-exists-p (merge-pathnames +manifest-file-name+ root)))
                   (make-federated :entry entry :root root :problem :no-manifest))
                  (t
                   (let ((other (load-corpus root :skip-unmarked t)))
                     (make-federated
                      :entry entry :root root :manifest (corpus-manifest other) :corpus other
                      :problem (unless (member (federation-entry-namespace entry)
                                               (manifest-namespaces (corpus-manifest other))
                                               :test #'string=)
                                 :not-owned)))))))
        (corpus-federation-loaded-p corpus) t)
  corpus)

(defun namespace-root (corpus namespace)
  "The root of the repository whose code a reference prefixed with NAMESPACE is
read in: CORPUS's own for NIL or a namespace it owns, else that of the loaded
federated repository owning NAMESPACE, or NIL."
  (if (or (null namespace) (corpus-owned-namespace-p corpus namespace))
      (corpus-root corpus)
      (loop for f in (corpus-federation corpus)
            when (and (federated-corpus f) (null (federated-problem f))
                      (member namespace (manifest-namespaces (federated-manifest f))
                              :test #'string=))
              return (federated-root f))))

(defun federated-location (corpus document written)
  "For WRITTEN, the path part of a link in DOCUMENT that leaves the repository:
the federated corpus it leads into and the path there, or NIL if it leads into
none that is loaded."
  (let* ((base (uiop:pathname-directory-pathname (document-pathname document)))
         (target (uiop:merge-pathnames* (uiop:parse-unix-namestring (percent-decode written))
                                        base))
         (resolved (or (probe-file target) target)))
    (loop for f in (corpus-federation corpus)
          for other = (federated-corpus f)
          for root = (and other (null (federated-problem f))
                          (probe-file (corpus-root other)))
          when (and root (uiop:subpathp resolved root))
            return (values other
                           (let ((relative (uiop:unix-namestring
                                            (uiop:enough-pathname resolved root))))
                             (string-right-trim "/" relative))))))

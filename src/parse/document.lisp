;;;; document.lisp — Read a file into a document: split front-matter, parse it, scan the body
;;;;
;;;; Read-if: changing how a file becomes a document, or the load-time findings
;;;; See: COMPASS-DRAFT-toolchain-D7, COMPASS-DRAFT-toolchain-D21
;;;; Invariant: a syntax error in front-matter is one fm/syntax finding; the body is still scanned
;;;; Tests: tests/test-scanner.lisp

(in-package #:compass.parse)

(defun fence-line-p (line)
  (string= (string-right-trim '(#\Space #\Tab) line) "---"))

(defun split-front-matter (text-or-lines)
  "Locate the front-matter block. Return four values: its text (or NIL), the
line number of its first line, the index of the first body line, and a status,
:NONE, :OK, or :UNCLOSED."
  (let ((lines (if (stringp text-or-lines) (split-lines text-or-lines) text-or-lines)))
    (if (or (zerop (length lines)) (not (fence-line-p (aref lines 0))))
        (values nil nil 0 :none)
        (let ((close (position-if #'fence-line-p lines :start 1)))
          (if close
              (values (join-lines (subseq lines 1 close)) 2 (1+ close) :ok)
              (values nil 2 1 :unclosed))))))

(defun parse-front-matter (text &key path (start-line 2))
  "Parse front-matter TEXT. Return the YAML-MAPPING, or NIL and a list holding
one fm/syntax finding."
  (handler-case (values (parse-yaml-subset text :start-line start-line) '())
    (front-matter-syntax-error (e)
      (values nil
              (list (make-finding :rule "fm/syntax" :severity :error :path path
                                  :line (front-matter-syntax-error-line e)
                                  :column (front-matter-syntax-error-column e)
                                  :message (front-matter-syntax-error-message e)))))))

(defun parse-document (text &key path pathname)
  "Build a DOCUMENT from TEXT. PATH is its repository-relative path."
  (let ((lines (split-lines text))
        (findings '())
        (front-matter nil))
    (multiple-value-bind (fm-text fm-start body-start status) (split-front-matter lines)
      (case status
        (:unclosed
         (push (make-finding :rule "fm/syntax" :severity :error :path path :line 1
                             :column 1
                             :message "the front-matter block opened on line 1 is never ~
                                       closed with ---")
               findings))
        (:ok
         (multiple-value-bind (mapping problems)
             (parse-front-matter fm-text :path path :start-line fm-start)
           (setf front-matter mapping
                 findings (append problems findings)))))
      (let* ((id (parse-identifier
                  (let ((node (and front-matter (yaml-get front-matter "id"))))
                    (and (yaml-scalar-p node) (yaml-scalar-value node)))))
             (body (scan-body lines :start body-start
                                    :namespace (and id (identifier-namespace id))))
             (document (make-instance 'document
                                      :path path :pathname pathname :text text
                                      :lines lines
                                      :has-front-matter-p (not (eq status :none))
                                      :front-matter front-matter
                                      :body-start-line (1+ body-start)
                                      :sections (body-sections body)
                                      :records (body-records body)
                                      :links (body-links body)
                                      :images (body-images body)
                                      :tables (body-tables body)
                                      :fences (body-fences body)
                                      :code-spans (body-code-spans body)
                                      :load-findings (nreverse findings))))
        (dolist (record (document-records document))
          (setf (record-document record) document))
        document))))

(defun read-document (pathname &key (path (namestring pathname)))
  "Read the file at PATHNAME into a DOCUMENT. Return the document, or NIL and a
file/read finding if the file cannot be read as UTF-8 text."
  (handler-case (parse-document (read-text-file pathname) :path path :pathname pathname)
    (text-file-error (e)
      (values nil
              (make-finding :rule "file/read" :severity :error :path path :line 1
                            :message (format nil "cannot read the file as UTF-8 text: ~a"
                                             (text-file-error-reason e)))))))

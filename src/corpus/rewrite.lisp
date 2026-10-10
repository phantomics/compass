;;;; rewrite.lisp — Rewrite identifiers, and the heading anchors that change with them, across the corpus
;;;;
;;;; Read-if: changing what assign or renumber rewrites, or how anchors are followed
;;;; See: COMPASS-DRAFT-toolchain-D24, COMPASS-DRAFT-toolchain-D25
;;;; Invariant: only corpus documents are rewritten, and never their fenced code or block comments
;;;; Invariant: a rewrite changes only the lines it is allowed to, and keeps every line ending
;;;; Tests: tests/test-allocate.lisp

(in-package #:compass.corpus)

(defstruct (rewrite)
  path pathname old-text new-text (changed-lines '()))

(defparameter *rewritable-kinds* '(:front-matter :text :heading))

(defun text-line-ending (text)
  (if (search (coerce '(#\Return #\Newline) 'string) text)
      (coerce '(#\Return #\Newline) 'string)
      (string #\Newline)))

(defun lines-to-text (lines original)
  "Join LINES as ORIGINAL's lines were joined: the same line ending, and a final
newline only if ORIGINAL had one."
  (let* ((ending (text-line-ending original))
         (text (format nil (concatenate 'string "~{~a~^" ending "~}") (coerce lines 'list))))
    (if (and (plusp (length original))
             (char= (char original (1- (length original))) #\Newline))
        (concatenate 'string text ending)
        text)))

(defun rewrite-line (line table)
  "LINE with each whole identifier that TABLE maps replaced. Short record
references such as D6 are not touched: they are found, and reported, by
`ref/short-record` (COMPASS-DRAFT-toolchain-D26)."
  (replace-identifiers-in-text line (lambda (id) (gethash id table))))

(defun section-anchor-changes (old-document new-document)
  "An alist from the anchors of OLD-DOCUMENT's headings to those of the same
headings in NEW-DOCUMENT, for the anchors that changed."
  (let ((changes '()))
    (loop for old in (document-sections old-document)
          for new in (document-sections new-document)
          unless (string= (section-anchor old) (section-anchor new))
            do (push (cons (section-anchor old) (section-anchor new)) changes))
    (nreverse changes)))

(defparameter *fragment-end* '(#\) #\Space #\Tab #\" #\' #\>))

(defun replace-fragment (line start old new)
  "LINE with the first \"#OLD\" at or after START, followed by the end of a link
destination, replaced by \"#NEW\"; NIL if there is none."
  (let ((needle (concatenate 'string "#" old)))
    (loop for at = (search needle line :start2 start) then (search needle line :start2 (1+ at))
          while at
          do (let ((after (+ at (length needle))))
               (when (or (= after (length line)) (member (char line after) *fragment-end*))
                 (return (concatenate 'string (subseq line 0 at) "#" new
                                      (subseq line after))))))))

(defparameter *reference-fragment-scanner*
  (ppcre:create-scanner "#([^\\s)\\]\\[`'\"<>,;|]+)"))

(defun replace-reference-anchors (line id changes)
  "LINE with each \"ID#anchor\" whose anchor is in CHANGES given its new anchor.
A trailing full stop or colon is not part of an anchor."
  (let ((needle (concatenate 'string id "#"))
        (pieces '()) (end 0) (changed nil))
    (loop for at = (search needle line :start2 end)
          while at
          do (let* ((before (and (plusp at) (char line (1- at))))
                    (fragment-start (+ at (length id))))
               (if (and before (or (alphanumericp before) (char= before #\-)))
                   (progn (push (subseq line end fragment-start) pieces)
                          (setf end fragment-start))
                   (multiple-value-bind (s e) (ppcre:scan *reference-fragment-scanner* line
                                                          :start fragment-start)
                     (let* ((raw (and s (= s fragment-start) (subseq line (1+ s) e)))
                            (anchor (and raw (string-right-trim ".:" raw)))
                            (new (and anchor (cdr (assoc anchor changes :test #'string=)))))
                       (if new
                           (progn
                             (push (subseq line end (1+ fragment-start)) pieces)
                             (push new pieces)
                             (setf end (+ fragment-start 1 (length anchor)) changed t))
                           (progn
                             (push (subseq line end (1+ fragment-start)) pieces)
                             (setf end (1+ fragment-start)))))))))
    (if changed
        (progn (push (subseq line end) pieces)
               (apply #'concatenate 'string (nreverse pieces)))
        line)))

(defun plan-rewrites (corpus mapping &key (eligible (constantly t)))
  "The rewrites of CORPUS's documents that replace each identifier in MAPPING
(an alist from old to new identifier strings), and the heading anchors that
change as a result. ELIGIBLE, a function of a document's path and a line number,
says which lines may change. Return a list of REWRITEs, one per changed document."
  (let ((table (make-hash-table :test #'equal))
        (states '()))
    (loop for (old . new) in mapping do (setf (gethash old table) new))
    ;; 1. Identifiers.
    (dolist (document (corpus-documents corpus))
      (let* ((path (document-path document))
             (lines (copy-seq (document-lines document)))
             (kinds (document-line-kinds document))
             (changed '()))
        (loop for i from 0 below (length lines)
              when (and (member (aref kinds i) *rewritable-kinds*)
                        (funcall eligible path (1+ i)))
                do (let ((new (rewrite-line (aref lines i) table)))
                     (unless (string= new (aref lines i))
                       (setf (aref lines i) new)
                       (push (1+ i) changed))))
        (push (list document lines changed) states)))
    (setf states (nreverse states))
    ;; 2. Anchors that changed with the headings.
    (let ((anchor-changes (make-hash-table :test #'equal))
          (new-ids (make-hash-table :test #'equal)))
      (dolist (state states)
        (destructuring-bind (document lines changed) state
          (when changed
            (let ((new-document (parse-document (lines-to-text lines (document-text document))
                                                :path (document-path document))))
              (setf (gethash (document-path document) new-ids)
                    (or (document-id new-document) (document-id document)))
              (let ((changes (section-anchor-changes document new-document)))
                (when changes
                  (setf (gethash (document-path document) anchor-changes) changes)))))))
      ;; 3. Links and ID#anchor references to those anchors.
      (when (plusp (hash-table-count anchor-changes))
        (dolist (state states)
          (destructuring-bind (document lines changed) state
            (let* ((path (document-path document))
                   (current (parse-document (lines-to-text lines (document-text document))
                                            :path path))
                   (kinds (document-line-kinds current)))
              ;; Links, right to left, so that earlier positions stay valid.
              (dolist (link (sort (copy-list (append (document-links current)
                                                     (document-images current)))
                                  (lambda (a b)
                                    (or (> (location-line a) (location-line b))
                                        (and (= (location-line a) (location-line b))
                                             (> (location-column a) (location-column b)))))))
                (multiple-value-bind (kind target fragment)
                    (link-destination current (link-target link))
                  (let ((new (and (eq kind :local) fragment
                                  (cdr (assoc fragment (gethash target anchor-changes)
                                              :test #'string=)))))
                    (when new
                      (loop for line-number from (location-line link)
                              below (min (+ (location-line link) 4) (1+ (length lines)))
                            for start = (1- (or (location-column link) 1)) then 0
                            when (funcall eligible path line-number)
                              do (let ((replaced (replace-fragment
                                                  (aref lines (1- line-number)) start
                                                  fragment new)))
                                   (when replaced
                                     (setf (aref lines (1- line-number)) replaced)
                                     (pushnew line-number changed)
                                     (return))))))))
              ;; ID#anchor written in text.
              (maphash (lambda (target-path changes)
                         (let ((id (gethash target-path new-ids)))
                           (when id
                             (loop for i from 0 below (length lines)
                                   when (and (member (aref kinds i) *rewritable-kinds*)
                                             (funcall eligible path (1+ i)))
                                     do (let ((new (replace-reference-anchors
                                                    (aref lines i) id changes)))
                                          (unless (string= new (aref lines i))
                                            (setf (aref lines i) new)
                                            (pushnew (1+ i) changed)))))))
                       anchor-changes)
              (setf (third state) changed))))))
    (loop for (document lines changed) in states
          when changed
            collect (make-rewrite :path (document-path document)
                                  :pathname (document-pathname document)
                                  :old-text (document-text document)
                                  :new-text (lines-to-text lines (document-text document))
                                  :changed-lines (sort (copy-list changed) #'<)))))

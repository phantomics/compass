;;;; test-code-refs.lisp — Tests for Git-derived fields, code references, and the Git queries behind them

(in-package #:compass.tests)

(def-suite code-refs :in compass)
(in-suite code-refs)

(defun commit-as (root message &key (name "Tester") (email "tester@example.net") date)
  "Commit everything in ROOT as NAME, with the author DATE (YYYY-MM-DD) if given."
  (git-in root "add" "-A")
  (apply #'git-in root "-c" (format nil "user.name=~a" name)
         "-c" (format nil "user.email=~a" email)
         "commit" "-q" "--no-verify" "-m" message
         (and date (list (format nil "--date=~aT12:00:00" date)))))

(defun head-revision (root)
  (trim-whitespace (git-in root "rev-parse" "--short" "HEAD")))

;;; The Git queries

(test git-batch-queries
  (with-git-repository (root (list (list "src/a.lisp" (lines "(defun frob ())" "; café"))
                                   (list "doc/x.md" "x")))
    (let ((revision (head-revision root)))
      (is (equal '(:commit nil :blob nil :tree)
                 (git-object-types root (list (format nil "~a^{commit}" revision)
                                              "0000000^{commit}"
                                              (format nil "~a:src/a.lisp" revision)
                                              (format nil "~a:src/none.lisp" revision)
                                              (format nil "~a:src" revision)))))
      (let ((objects (git-read-objects root (list (format nil "~a:src/a.lisp" revision)
                                                  (format nil "~a:nope" revision)
                                                  (format nil "~a:doc/x.md" revision)))))
        (is (equal (cons :blob (lines "(defun frob ())" "; café")) (first objects))
            "text is decoded as UTF-8, and sizes are counted in bytes")
        (is (equal '(nil) (second objects)))
        (is (equal '(:blob . "x") (third objects))))
      (is (null (git-object-types root '())))
      (is (equal '("doc/x.md" "src/a.lisp") (sort (git-committed-files root) #'string<))))))

(test git-history-of-a-file
  (with-git-repository (root (list (list "doc/A.md" "one")) :name "Ada" :email "ada@example.net")
    (write-file root "doc/A.md" "two")
    (commit-as root "second" :name "phan" :email "p@example.net" :date "2026-03-04")
    (git-in root "mv" "doc/A.md" "doc/B.md")
    (commit-as root "rename" :name "Ada" :email "ada@example.net" :date "2026-05-06")
    (write-file root ".mailmap" (lines "Andrew Sengul <p@example.net>"))
    (let ((history (git-log-follow root "doc/B.md")))
      (is (= 3 (length history)))
      (is (equal '("Ada" "Andrew Sengul" "Ada") (mapcar #'first history))
          "oldest first, through the rename, as .mailmap names them")
      (is (equal '("2026-03-04" "2026-05-06") (mapcar #'second (rest history)))))
    (is (eq :clean (git-file-status root "doc/B.md")))
    (write-file root "doc/B.md" "three")
    (is (eq :modified (git-file-status root "doc/B.md")))
    (write-file root "doc/C.md" "new")
    (is (eq :untracked (git-file-status root "doc/C.md")))
    (is (null (git-log-follow root "doc/C.md")))))

;;; Derived fields (D27)

(defun field-values (corpus path)
  (mapcar (lambda (f) (list (derived-field-name f) (derived-field-value f)
                            (derived-field-source f)))
          (document-derived-fields corpus (document-at-path corpus path))))

(test derived-fields
  (with-git-repository (root (list (list "doc/Plan.A.md" (doc :authors nil))
                                   (list "doc/Plan.B.md" (doc :id "TEST-0002"
                                                              :created "2026-01-01")))
                             :name "Ada" :email "ada@example.net")
    (git-in root "commit" "-q" "--amend" "--no-edit" "--date=2026-02-03T12:00:00")
    (write-file root "doc/Plan.A.md" (doc :authors nil :title "Changed"))
    (commit-as root "edit" :name "Bob" :email "bob@example.net" :date "2026-02-10")
    (let ((corpus (load-corpus root)))
      (is (equal '(("authors" ("Ada" "Bob") :git) ("created" "2026-02-03" :git)
                   ("updated" "2026-02-10" :git))
                 (field-values corpus "doc/Plan.A.md")))
      (is (equal '(("authors" ("Tester") :front-matter) ("created" "2026-01-01" :front-matter)
                   ("updated" "2026-02-03" :git))
                 (field-values corpus "doc/Plan.B.md"))
          "a value in front-matter wins"))
    ;; Uncommitted work credits the current user, today.
    (git-in root "config" "user.name" "Tester")
    (write-file root "doc/Plan.A.md" (doc :authors nil :title "Changed again"))
    (write-file root "doc/Plan.C.md" (doc :id "TEST-0003" :authors nil))
    (let ((corpus (load-corpus root)))
      (is (equal `(("authors" ("Ada" "Bob" "Tester") :git) ("created" "2026-02-03" :git)
                   ("updated" ,(today) :working-tree))
                 (field-values corpus "doc/Plan.A.md")))
      (is (equal `(("authors" ("Tester") :working-tree) ("created" ,(today) :working-tree)
                   ("updated" ,(today) :working-tree))
                 (field-values corpus "doc/Plan.C.md")))
      (is (null (check-corpus corpus :only '("git/derivable")))))))

(test derived-fields-in-outline
  (with-git-repository (root (list (list "doc/Plan.A.md" (doc :authors nil))))
    (multiple-value-bind (code out) (run-cli "outline" "TEST-0001" (root-arg root))
      (is (= 0 code))
      (is (search (format nil "Authors: Tester (Git); Created: ~a (Git); Updated: ~a (Git)"
                          (today) (today))
                  out)))
    (multiple-value-bind (code out) (run-cli "outline" "TEST-0001" "--format" "json"
                                             (root-arg root))
      (is (= 0 code))
      (let ((authors (gethash "authors" (gethash "fields" (shasht:read-json out)))))
        (is (equalp #("Tester") (gethash "value" authors)))
        (is (equal "git" (gethash "source" authors)))))))

(test git-derivable
  (flet ((messages (findings)
           (mapcar #'finding-message (findings-of findings "git/derivable"))))
    ;; Outside a repository nothing can be derived.
    (let ((findings (check-files (list (list "doc/Plan.A.md" (doc :authors nil)))
                                 :rules '("git/derivable"))))
      (is (= 1 (length findings)))
      (is (search "`created` and `authors` are not in front-matter and cannot be derived from Git, because doc/Plan.A.md is not in a Git work tree; write them in front-matter"
                  (first (messages findings)))))
    (is (null (check-files (list (list "doc/Plan.A.md" (doc :created "2026-10-09")))
                           :rules '("git/derivable")))
        "nothing is missing")
    ;; An uncommitted file needs someone to credit.
    (with-git-repository (root (list (list "doc/Plan.A.md" (doc))))
      (git-in root "config" "user.name" "")
      (write-file root "doc/Plan.B.md" (doc :id "TEST-0002"))
      (let ((findings (check-corpus (load-corpus root) :only '("git/derivable"))))
        (is (= 1 (length findings)) "the committed file derives from its history")
        (is (has-finding-p findings "git/derivable" :path "doc/Plan.B.md"))
        (is (search "no user.name to credit; set a name with git config user.name"
                    (first (messages findings))))))
    ;; Without Git, a note.
    (let ((*git-program* "compass-test-no-such-git"))
      (multiple-value-bind (findings corpus)
          (check-files (list (list "doc/Plan.A.md" (doc))) :rules '("git/derivable"))
        (is (null findings))
        (is (equal '("git/derivable did not run: Git was not found")
                   (corpus-notes corpus)))))))

;;; What is a code reference

(defun mention-parts (text &key files manifest)
  (with-temp-repository (root (append (and manifest (list (list "compass.sexp" manifest)))
                                      files))
    (let ((m (parse-code-mention (load-corpus root) text)))
      (and m (list (code-mention-namespace m) (code-mention-path m) (code-mention-symbol m)
                   (code-mention-line-start m) (code-mention-line-end m)
                   (code-mention-line m) (code-mention-revision m))))))

(test code-mentions
  (is (equal '(nil "src/a.lisp" "frob" nil nil nil "a1b3f9c")
             (mention-parts "src/a.lisp:frob@a1b3f9c")))
  (is (equal '(nil "src/a.lisp" nil 3 9 nil "v1.0") (mention-parts "src/a.lisp#L3-L9@v1.0")))
  (is (equal '(nil "src/a.lisp" nil nil nil 42 nil) (mention-parts "src/a.lisp:42")))
  (is (equal '(nil "build.lisp" "stamp-build" nil nil nil nil)
             (mention-parts "build.lisp:stamp-build")))
  (is (equal '(nil "Makefile" nil nil nil nil "abc1234")
             (mention-parts "Makefile@abc1234" :files (list (list "Makefile" "all:")))))
  (is (null (mention-parts "Makefile@abc1234")) "no such file, no extension, no slash")
  (is (equal '(nil "README" "install" nil nil nil nil)
             (mention-parts "README:install" :files (list (list "README" "x"))))
      "a prefix that is not a namespace is part of the path")
  (is (equal '("CLASSIC" "src/uri.lisp" nil nil nil nil "6e4f02d")
             (mention-parts "CLASSIC:src/uri.lisp@6e4f02d"
                            :manifest "(:namespaces (\"TEST\") :federation ((:namespace \"CLASSIC\" :path \"../classic\")))")))
  ;; Not code references.
  (dolist (text '("compass.cli:main" "path:symbol@revision" "rev:./path" "main:doc/x.md"
                  "https://example.net/a.lisp" "[NS:]path" "(defun x)" "a b.lisp:c"))
    (is (null (mention-parts text)) "~s is not a code reference" text)))

(defparameter *code-files*
  (list (list "src/a.lisp" (lines "(in-package #:a)" "(defun frob (x) x)"
                                  "(define-rule \"ledger/unique\" ())" "(defclass thing ()"
                                  "  ((size :reader thing-size)))" "(test frob-works)"))
        (list "src/b.py" (lines "class Widget:" "    def spin(self):" "        pass"
                                "LIMIT = 3"))
        (list "src/c.js" (lines "export function draw() {}" "const radius = 2;"))
        (list "notes.md" (lines "# Notes" "The word zebra appears once."))))

(defun log-doc (&rest body-lines)
  (doc :genre "Log" :created "2026-10-09" :body (apply #'lines "# Log" "" body-lines)))

(defun code-findings (revision-lines &key (rules '("ref/code-pinned" "ref/code-exists"))
                                          (genre "Log"))
  "Commit *CODE-FILES*, then check a document of GENRE whose body, from line 14,
is REVISION-LINES, with REV standing for the revision."
  (with-git-repository (root *code-files*)
    (let ((revision (head-revision root)))
      (write-file root "doc/Log.A.md"
                  (doc :genre genre :created "2026-10-09"
                       :body (format nil "# Log~%~%~{~a~%~}"
                                     (mapcar (lambda (l) (ppcre:regex-replace-all "REV" l revision))
                                             revision-lines))))
      (let ((corpus (load-corpus root)))
        (values (check-corpus corpus :only rules) corpus)))))

(test code-references-that-resolve
  (multiple-value-bind (findings corpus)
      (code-findings '("`src/a.lisp:frob@REV`, `src/a.lisp:ledger/unique@REV`,"
                       "`src/a.lisp:thing@REV`, `src/a.lisp:thing-size@REV`,"
                       "`src/a.lisp:frob-works@REV`, `src/a.lisp:a::frob@REV`,"
                       "`src/b.py:Widget.spin@REV`, `src/b.py:LIMIT@REV`,"
                       "`src/c.js:draw@REV`, `src/c.js:radius@REV`,"
                       "`notes.md:zebra@REV`, `src/a.lisp#L2-L6@REV`, `src@REV`,"
                       "`src/a.lisp@HEAD`, and in a heading:" "" "## About `src/a.lisp:frob@REV`"))
    (is (null findings) (describe-findings findings))
    (is (= 15 (length (document-code-mentions corpus (first (corpus-documents corpus))))))))

(test code-references-that-do-not-resolve
  (let ((findings (code-findings '("`src/a.lisp:frob@0000000`"
                                   "`src/none.lisp:frob@REV`"
                                   "`src/a.lisp:missing@REV`"
                                   "`src/a.lisp#L5-L99@REV`"
                                   "`src/b.py:Gadget@REV`"
                                   "`notes.md:giraffe@REV`"
                                   "`src:frob@REV`"))))
    (is (= 7 (length findings)) (describe-findings findings))
    (is (has-finding-p findings "ref/code-exists" :line 14 :severity :error))
    (is (search "the revision 0000000 of `src/a.lisp:frob@0000000` names no commit or tag"
                (finding-message (first findings))))
    (is (has-finding-p findings "ref/code-exists" :line 15 :severity :error))
    (is (search "src/none.lisp does not exist at" (finding-message (second findings))))
    (dolist (line '(16 17 18 19 20))
      (is (has-finding-p findings "ref/code-exists" :line line :severity :warning)))
    (is (search "src/a.lisp defines no missing at" (finding-message (third findings))))
    (is (search "src/a.lisp has 6 lines at" (finding-message (fourth findings))))))

(test code-references-pinned
  (let ((findings (code-findings '("`src/a.lisp:frob` and `src/a.lisp#L2` and `src/a.lisp:2`"
                                   "and `src/a.lisp:2@REV`; a bare `src/a.lisp` is fine,"
                                   "as are `ledger/unique`, `compass.cli:main`, and"
                                   "`path:symbol@revision`.")
                                 :rules '("ref/code-pinned"))))
    (is (= 4 (length findings)) (describe-findings findings))
    (is (every (lambda (f) (eq :error (finding-severity f))) findings) "errors in a Log")
    (is (search "`src/a.lisp:frob` names a place in code but no revision; pin it to a commit, as `src/a.lisp:frob@<commit>`"
                (finding-message (first findings))))
    (is (search "as `src/a.lisp#L2@<commit>`, and write the line as `#L2`"
                (finding-message (third findings))))
    (is (search "`src/a.lisp:2@" (finding-message (fourth findings))))
    (is (search "gives a line as `:2`; write it `#L2`" (finding-message (fourth findings)))))
  (let ((findings (code-findings '("`src/a.lisp:frob`") :rules '("ref/code-pinned")
                                                        :genre "Survey")))
    (is (= 1 (length findings)))
    (is (eq :warning (finding-severity (first findings))) "a warning outside Log and Plan")))

(test code-references-unverified-and-without-git
  ;; A namespace that is not loaded: counted, not reported.
  (with-git-repository (root (list (list "compass.sexp" *ledger-manifest*)))
    (write-file root "doc/Log.A.md" (log-doc "See `OTHER:src/x.lisp:f@abc1234`."))
    (let* ((corpus (load-corpus root))
           (findings (check-corpus corpus :only '("ref/code-exists"))))
      (is (null findings))
      (is (equal '("OTHER:src/x.lisp:f@abc1234")
                 (mapcar #'third (corpus-unverified corpus))))))
  ;; Outside a Git repository: a note.
  (multiple-value-bind (findings corpus)
      (check-files (list (list "doc/Log.A.md" (log-doc "See `src/a.lisp:f@abc1234`.")))
                   :rules '("ref/code-exists"))
    (is (null findings))
    (is (= 1 (length (corpus-notes corpus))))
    (is (starts-with-p "ref/code-exists did not run: " (first (corpus-notes corpus))))
    (is (ends-with-p " is not in a Git repository" (first (corpus-notes corpus))))))

(test memo-basis-revisions
  (with-git-repository (root *code-files*)
    (let ((revision (head-revision root)))
      (flet ((memo (basis)
               (write-file root "doc/Memo.A.md"
                           (doc :genre "Memo" :status "Current" :scope "component"
                                :created "2026-10-09" :extra '("memos:" "  - TEST-M1")
                                :body (lines "# A: Memos" "" "## Memos" ""
                                             "### TEST-M1 — Frobbing is idempotent" ""
                                             "**Status:** Current"
                                             "**Read-if:** changing frob"
                                             (format nil "**Basis:** ~a; observed" basis))))
               (check-corpus (load-corpus root) :only '("memo/basis" "ref/code-exists"))))
        (is (null (memo (format nil "`src/a.lisp:frob@~a`" revision))))
        (let ((findings (memo "`src/a.lisp:frob@0000000`")))
          (is (= 1 (length findings)) "reported once, by memo/basis")
          (is (has-finding-p findings "memo/basis"))
          (is (search "whose revision 0000000 names no commit or tag"
                      (finding-message (first findings)))))
        (let ((findings (memo (format nil "`src/a.lisp:gone@~a`" revision))))
          (is (equal '("ref/code-exists") (mapcar #'finding-rule findings))))))))

(test shallow-clones
  (with-git-repository (origin (list (list "src/a.lisp" (lines "(defun frob ())"))
                                     (list "doc/Plan.A.md" (doc :authors nil))))
    (let ((first (head-revision origin)))
      (write-file origin "src/a.lisp" (lines "(defun frob ())" "(defun spin ())"))
      (commit-all origin "second")
      (with-temp-repository (scratch '())
        (let ((clone (merge-pathnames "clone/" scratch)))
          (git-in scratch "clone" "-q" "--depth" "1"
                  (concatenate 'string "file://" (uiop:native-namestring origin))
                  (uiop:native-namestring clone))
          (write-file clone "doc/Log.A.md"
                      (log-doc (format nil "See `src/a.lisp:frob@~a`." first)))
          (multiple-value-bind (findings corpus)
              (let ((corpus (load-corpus clone)))
                (values (check-corpus corpus :only '("ref/code-exists")) corpus))
            (is (null findings) "a revision missing from a shallow clone is unverified")
            (is (= 1 (length (corpus-unverified corpus))))
            (let ((created (find "created" (document-derived-fields
                                            corpus (document-at-path corpus "doc/Plan.A.md"))
                                 :key #'derived-field-name :test #'string=)))
              (is (search "shallow clone" (derived-field-note created))))))))))

(test symbol-definitions
  (is-true (symbol-defined-p "a.lisp" "frob" "(defun frob (x)"))
  (is-true (symbol-defined-p "a.lisp" "FROB" "(DEFUN frob (x)"))
  (is-true (symbol-defined-p "a.lisp" "ledger/unique" "(define-rule \"ledger/unique\" (:x"))
  (is-true (symbol-defined-p "a.lisp" "entry" "(defstruct (entry (:include x))"))
  (is-true (symbol-defined-p "a.lisp" "pkg" "(defpackage #:pkg"))
  (is-true (symbol-defined-p "a.lisp" "*x*" (lines ";; x" "(defparameter *x* 1)")))
  (is-false (symbol-defined-p "a.lisp" "frob" "(frob 1)"))
  (is-false (symbol-defined-p "a.lisp" "frob" "(defun frobnicate ())"))
  (is-true (symbol-defined-p "a.go" "Run" "func (s *Server) Run() error {"))
  (is-true (symbol-defined-p "a.rs" "parse" "pub fn parse(input: &str)"))
  (is-true (symbol-defined-p "a.c" "main" "int main(int argc, char **argv)"))
  (is-false (symbol-defined-p "a.c" "main" "  return main(1, x);"))
  (is-true (symbol-defined-p "a.sh" "build" "build() {"))
  (is-true (symbol-defined-p "Makefile" "install" "install: build"))
  (is-false (symbol-defined-p "Makefile" "install" "reinstall: build")))

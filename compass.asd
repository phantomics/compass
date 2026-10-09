;;;; compass.asd — ASDF systems for the Compass validation toolchain
;;;;
;;;; Read-if: adding a source file, a dependency, or changing how the executable is built
;;;; See: COMPASS-DRAFT-toolchain
;;;; Invariant: dependencies are pure Lisp and available from both Quicklisp and ocicl

(asdf:defsystem "compass"
  :description "Validation toolchain for the Compass documentation standard"
  :version "0.1.0"
  :author "Andrew Sengul"
  :license "BSD-3-Clause"
  :depends-on ("alexandria" "cl-ppcre" "shasht")
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "packages")
     (:file "util")
     (:file "vocab")
     (:module "model"
      :serial t
      :components ((:file "identifier")
                   (:file "sexp")
                   (:file "document")
                   (:file "fields")
                   (:file "manifest")))
     (:module "parse"
      :serial t
      :components ((:file "yaml")
                   (:file "inline")
                   (:file "scanner")
                   (:file "document")))
     (:module "corpus"
      :serial t
      :components ((:file "corpus")
                   (:file "show")
                   (:file "index")
                   (:file "outline")
                   (:file "refs")))
     (:module "rules"
      :serial t
      :components ((:file "engine")
                   (:file "frontmatter")
                   (:file "identity")
                   (:file "registers")
                   (:file "memo")
                   (:file "references")))
     (:file "report")
     (:file "cli"))))
  :build-operation "program-op"
  :build-pathname "bin/compass"
  :entry-point "compass.cli:main"
  :in-order-to ((test-op (test-op "compass/tests"))))

(asdf:defsystem "compass/tests"
  :description "FiveAM test suite for the Compass validation toolchain"
  :depends-on ("compass" "fiveam")
  :components
  ((:module "tests"
    :serial t
    :components ((:file "package")
                 (:file "helpers")
                 (:file "test-util")
                 (:file "test-vocab")
                 (:file "test-identifier")
                 (:file "test-sexp")
                 (:file "test-yaml")
                 (:file "test-scanner")
                 (:file "test-rules")
                 (:file "test-corpus")
                 (:file "test-cli")
                 (:file "test-repository"))))
  :perform (test-op (o c)
             (unless (uiop:symbol-call :compass.tests :run-tests)
               (error "Compass test suite failed"))))

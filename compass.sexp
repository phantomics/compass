;;; compass.sexp — Compass project manifest for this repository
;;;
;;; Read by the toolchain with a restricted reader: strings, integers,
;;; keywords, and lists only (COMPASS-DRAFT-toolchain-D4, D15).

(:namespaces ("COMPASS")
 :doc-directory "doc/"
 :commands ((:name :build :shell "make build"
             :doc "Build bin/compass")
            (:name :test :shell "make test"
             :doc "Run the toolchain's test suite")
            (:name :check :shell "make check"
             :doc "Build the toolchain and check this repository's corpus"))
 :stewards ((:namespace "COMPASS" :steward "Andrew Sengul" :approval :solo)))

#lang info

(define collection 'multi)
(define deps '("base" "scribble-lib"))
(define build-deps '("racket-doc" "rackunit-lib"))
(define pkg-desc "Racket bindings and functional modeling API for Manifold")
(define version "0.1.0")
(define pkg-authors '("Josh Stone"))
(define license 'MIT)
(define test-omit-paths '("examples" "scripts"))
(define scribblings '(("scribblings/manifold.scrbl" (multi-page))))

#lang racket/base

(require racket/cmdline
         racket/runtime-path
         "support.rkt")

(define-runtime-path examples-directory ".")

(define examples
  '("01-cube.rkt"
    "02-primitives-and-transforms.rkt"
    "03-boolean-bracket.rkt"
    "04-hull-and-minkowski.rkt"
    "05-cross-section-extrusion.rkt"
    "06-sdf-and-warp.rkt"
    "07-mesh-round-trip.rkt"
    "08-pocket-tug.rkt"))

(command-line
 #:program "manifold-examples"
 #:once-each
 [("-o" "--output") directory "Directory for generated STL and OBJ files"
  (example-output-directory (path->complete-path directory))])

(for ([filename (in-list examples)])
  (printf "\n== ~a ==\n" filename)
  ((dynamic-require (build-path examples-directory filename) 'run)))

(printf "\nAll examples completed. Artifacts are in ~a\n"
        (example-output-directory))

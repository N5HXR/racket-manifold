#lang racket/base

(require "../manifold/units.rkt")

(define conductor
  (with-units millimetre
    (capsule '(0 0 0) '(0 0 10) 1 #:segments 32)))

(with-units millimetre
  (write-stl conductor "capsule-mm.stl" #:name "capsule"))

(solid-close! conductor)

#lang racket/base

(require "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (run)
  (define model
    (with-units millimetre
      (cube 20 12 6 #:center? #t)))
  (emit-stl "01-cube" model)
  (solid-close! model))

(module+ main (run))

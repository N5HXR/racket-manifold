#lang racket/base

(require "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (run)
  (define-values (block ball cone rod model)
    (with-units millimetre
      (define block (translate (cube 12 12 8 #:center? #t) '(-22 0 4)))
      (define ball (translate (sphere 7 #:segments 32) '(-7 0 7)))
      (define cone
        (translate
         (cylinder 16 7 #:top-radius 2 #:segments 32 #:center? #t)
         '(10 0 8)))
      (define rod
        (translate
         (rotate (scale (cylinder 18 3 #:segments 24 #:center? #t)
                        1 0.65 1)
                 0 35 0)
         '(26 0 9)))
      (values block ball cone rod (union block ball cone rod))))
  (emit-stl "02-primitives-and-transforms" model)
  (close-solids block ball cone rod model))

(module+ main (run))

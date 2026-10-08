#lang racket/base

(require "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (run)
  (define-values (base upright boss-a boss-b joined hole-a hole-b slotted model)
    (with-units millimetre
      (define base (translate (cube 50 24 5 #:center? #t) '(0 0 2.5)))
      (define upright (translate (cube 6 24 30 #:center? #t) '(-22 0 17.5)))
      (define boss-a (translate (cylinder 7 6 #:segments 32) '(15 0 5)))
      (define boss-b (translate (cylinder 7 6 #:segments 32) '(-5 0 5)))
      (define joined (union base upright boss-a boss-b))
      (define hole-a (translate (cylinder 20 2.6 #:segments 28 #:center? #t) '(15 0 5)))
      (define hole-b (translate (cylinder 20 2.6 #:segments 28 #:center? #t) '(-5 0 5)))
      (define slot-envelope
        (intersection
         (translate (cube 12 30 12 #:center? #t) '(-22 0 18))
         (translate (sphere 10 #:segments 32) '(-22 0 18))))
      (define slotted (difference joined hole-a hole-b slot-envelope))
      (values base upright boss-a boss-b joined hole-a hole-b slotted slotted)))
  (emit-stl "03-boolean-bracket" model)
  ;; `model` and `slotted` are the same handle here; close it only once.
  (close-solids base upright boss-a boss-b joined hole-a hole-b slotted))

(module+ main (run))

#lang racket/base

(require "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (run)
  (define-values (p1 p2 p3 p4 outer inner rounded-key model)
    (with-units millimetre
      (define p1 (translate (sphere 6 #:segments 28) '(-22 -9 0)))
      (define p2 (translate (sphere 6 #:segments 28) '(22 -9 0)))
      (define p3 (translate (sphere 6 #:segments 28) '(-22 9 0)))
      (define p4 (translate (sphere 6 #:segments 28) '(22 9 0)))
      (define outer (hull p1 p2 p3 p4))
      (define inner
        (hull (translate (sphere 3 #:segments 24) '(-17 0 0))
              (translate (sphere 3 #:segments 24) '(17 0 0))))
      (define rounded-key
        (minkowski-sum (cube 7 7 2 #:center? #t)
                       (sphere 1.5 #:segments 20)))
      (define model
        (union (difference outer inner)
               (translate rounded-key '(0 -13 0))))
      (values p1 p2 p3 p4 outer inner rounded-key model)))
  (emit-stl "04-hull-and-minkowski" model)
  (close-solids p1 p2 p3 p4 outer inner rounded-key model))

(module+ main (run))

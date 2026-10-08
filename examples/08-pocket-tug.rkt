#lang racket/base

(require "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (run)
  (define-values (hull-a hull-b hull-c raw-hull waterline hull-solid deck cabin roof
                         stack mast window-a window-b assembled model)
    (with-units millimetre
      (with-circular-segments 128
        ;; Three overlapping ellipsoids give the hull a full stern and narrow bow.
        (define hull-a (translate (scale (sphere 1) 30 15 10) '(-12 0 9)))
        (define hull-b (translate (scale (sphere 1) 25 13 9) '(12 0 9)))
        (define hull-c (translate (scale (sphere 1 #:segments 32) 10 6 7) '(34 0 10)))
        (define raw-hull (hull hull-a hull-b hull-c))
        (define waterline (translate (cube 90 40 15 #:center? #t) '(0 0 7.5)))
        (define hull-solid (intersection raw-hull waterline))

        (define deck (translate (cube 52 22 3 #:center? #t) '(-2 0 16)))
        (define cabin (translate (cube 24 18 13 #:center? #t) '(-8 0 23.5)))
        (define roof
          (translate (scale (sphere 1) 15 11 3) '(-8 0 30)))
        (define stack
          (translate (cylinder 11 3.2 #:top-radius 2.5 #:segments 28) '(3 0 29)))
        (define mast (capsule '(17 0 18) '(17 0 39) 1.1 #:segments 20))

        ;; Two transverse cylinders become printable cabin windows.
        (define window-a
          (translate (rotate (cylinder 30 2.4 #:segments 24 #:center? #t) 90 0 0)
                     '(-13 0 25)))
        (define window-b
          (translate (rotate (cylinder 30 2.4 #:segments 24 #:center? #t) 90 0 0)
                     '(-3 0 25)))
        (define assembled (union hull-solid deck cabin roof stack mast))
        (define model (difference assembled window-a window-b))
        (values hull-a hull-b hull-c raw-hull waterline hull-solid deck cabin roof stack
                mast window-a window-b assembled model))))
  (emit-stl "08-pocket-tug" model)
  (close-solids hull-a hull-b hull-c raw-hull waterline hull-solid deck cabin roof
                stack mast window-a window-b assembled model))

(module+ main (run))

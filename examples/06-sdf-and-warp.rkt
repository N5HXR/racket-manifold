#lang racket/base

(require racket/math
         "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (torus-distance x y z)
  (define radial (- (sqrt (+ (* x x) (* y y))) 13.0))
  (- (sqrt (+ (* radial radial) (* z z))) 4.0))

(define (twist x y z)
  (define angle (* 0.035 z))
  (define c (cos angle))
  (define s (sin angle))
  (list (- (* c x) (* s y)) (+ (* s x) (* c y)) z))

(define (run)
  ;; Layer 2 converts callback coordinates and distances through the unit
  ;; context and chooses Manifold's sequential callback entry point.
  (with-units millimetre
    (define torus (level-set torus-distance '(-19 -19 -5) '(19 19 5) 0.9))
    (define warped (warp torus twist))
    (printf "06-sdf-and-warp: volume ~a; ~a triangles\n"
            (solid-volume warped) (solid-num-triangles warped))
    (emit-obj "06-sdf-and-warp" (solid->obj-string warped))
    (emit-stl "06-sdf-and-warp" warped)
    (solid-close! torus)
    (solid-close! warped)))

(module+ main (run))

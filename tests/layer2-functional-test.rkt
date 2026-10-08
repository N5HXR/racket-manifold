#lang racket/base

(require rackunit
         racket/math
         racket/port
         manifold
         (prefix-in u: manifold/units)
         manifold/private/library)

(define (close-cross-sections . values)
  (for-each cross-section-close! values))

(unless (manifold-library-available?)
  (eprintf "Skipping native Manifold integration tests: libmanifoldc is unavailable\n"))

(when (manifold-library-available?)

(test-case "Layer 2 planar CSG, bounds, extrusion, and revolution"
  (define plate (square 20 10 #:center? #t))
  (define hole (circle 2 #:segments 24))
  (define shifted (cross-section-translate hole '(6 0)))
  (define profile (cross-section-difference plate hole shifted))
  (check-= (cross-section-area profile) (- 200 (* 2 pi 4)) 0.3)
  (define-values (minimum maximum) (cross-section-bounds profile))
  (check-equal? minimum '(-10.0 -5.0))
  (check-equal? maximum '(10.0 5.0))
  (define solid (extrude profile 3))
  (check-= (solid-volume solid) (* 3 (cross-section-area profile)) 1e-7)
  (define revolved-profile (polygon '((3 0) (5 0) (5 2) (3 2))))
  (define ring (revolve revolved-profile #:segments 32))
  (check-false (solid-empty? ring))
  (close-cross-sections plate hole shifted profile revolved-profile)
  (solid-close! solid)
  (solid-close! ring))

(test-case "Layer 2 split, slice, and projection"
  (define value (cube 4 #:center? #t))
  (define cutter (translate (cube 2 6 6 #:center? #t) '(1 0 0)))
  (define-values (inside outside) (split value cutter))
  (check-= (solid-volume inside) 32.0 1e-9)
  (check-= (solid-volume outside) 32.0 1e-9)
  (define section (solid-slice value 0))
  (define projection (solid-project value))
  (check-= (cross-section-area section) 16.0 1e-9)
  (check-= (cross-section-area projection) 16.0 1e-9)
  (for-each solid-close! (list value cutter inside outside))
  (close-cross-sections section projection))

(test-case "Layer 2 mesh round trip and ray casts"
  (define original (tetrahedron))
  (define data (solid->mesh original))
  (define rebuilt (mesh->solid data))
  (check-= (solid-volume rebuilt) (solid-volume original) 1e-12)
  (define hits (solid-ray-cast rebuilt '(-1 0.1 0.1) '(2 0.1 0.1)))
  (check-equal? (length hits) 2)
  (check-true (andmap ray-hit? hits))
  (solid-close! original)
  (solid-close! rebuilt))

(test-case "Layer 2 sequential level set, warp, and OBJ conveniences"
  (define implicit
    (level-set (lambda (x y z) (- (sqrt (+ (* x x) (* y y) (* z z))) 1))
               '(-1.3 -1.3 -1.3) '(1.3 1.3 1.3) 0.35))
  (define warped (warp implicit (lambda (x y z) (list (+ x (* z 0.1)) y z))))
  (check-false (solid-empty? warped))
  (define text (solid->obj-string warped))
  (check-true (regexp-match? #rx"^#" text))
  (define from-port (read-obj (open-input-string text)))
  (check-= (solid-volume from-port) (solid-volume warped) 1e-8)
  (define out (open-output-string))
  (write-obj from-port out)
  (check-true (positive? (string-length (get-output-string out))))
  (for-each solid-close! (list implicit warped from-port)))

(test-case "unit facade covers planar construction and mesh round trips"
  (define section
    (u:with-units u:millimetre
      (u:cross-section-difference
       (u:square 20 10 #:center? #t)
       (u:circle 2 #:segments 24))))
  (check-= (u:with-units u:millimetre (u:cross-section-area section))
           (- 200 (* pi 4)) 0.2)
  (define solid (u:with-units u:millimetre (u:extrude section 3)))
  (define data (u:with-units u:millimetre (u:solid->mesh solid)))
  (define rebuilt (u:with-units u:millimetre (u:mesh->solid data)))
  (check-= (u:with-units u:millimetre (u:solid-volume rebuilt))
           (u:with-units u:millimetre (u:solid-volume solid)) 1e-7)
  (u:cross-section-close! section)
  (u:solid-close! solid)
  (u:solid-close! rebuilt))

(test-case "unit facade scales SDF callbacks and OBJ coordinates"
  (define implicit
    (u:with-units u:millimetre
      (u:level-set
       (lambda (x y z) (- (sqrt (+ (* x x) (* y y) (* z z))) 10))
       '(-13 -13 -13) '(13 13 13) 3)))
  (check-true (> (u:with-units u:millimetre (u:solid-volume implicit)) 3000))
  (define text (u:with-units u:millimetre (u:solid->obj-string implicit)))
  (define imported
    (u:with-units u:millimetre (u:read-obj (open-input-string text))))
  (check-= (u:with-units u:millimetre (u:solid-volume imported))
           (u:with-units u:millimetre (u:solid-volume implicit)) 1e-5)
  (u:solid-close! implicit)
  (u:solid-close! imported)))

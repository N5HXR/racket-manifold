#lang racket/base

(require rackunit
         racket/math
         racket/port
         manifold
         (prefix-in u: manifold/units)
         manifold/coverage)

(define tolerance 1e-9)
(define (close? a b [epsilon tolerance]) (< (abs (- a b)) epsilon))

(test-case "target library and coverage manifest"
  (check-equal? (manifold-version) '(3 5 1))
  (check-equal? api-symbol-count 292)
  (check-equal? (length api-bound-symbols) 292)
  (check-equal? (length api-managed-symbols) 292)
  (check-equal? api-unsafe-only-symbols '())
  (check-equal? api-pending-symbols '()))

(test-case "every official C symbol has a resolvable raw procedure"
  (for ([symbol (in-list api-bound-symbols)])
    (check-true (procedure? (dynamic-require 'manifold/unsafe symbol))
                (symbol->string symbol))))

(test-case "cube ownership, measurements, bounds, and explicit close"
  (define value (cube 1 2 3))
  (check-equal? (solid-volume value) 6.0)
  (check-equal? (solid-surface-area value) 22.0)
  (check-equal? (solid-num-vertices value) 8)
  (check-equal? (solid-num-triangles value) 12)
  (define-values (minimum maximum) (solid-bounds value))
  (check-equal? minimum (point3 0.0 0.0 0.0))
  (check-equal? maximum (point3 1.0 2.0 3.0))
  (solid-close! value)
  (check-true (solid-closed? value))
  (check-not-exn (lambda () (solid-close! value)))
  (check-exn exn:fail? (lambda () (solid-volume value))))

(test-case "Boolean operations"
  (define a (cube 2 #:center? #t))
  (define b (translate (cube 2 #:center? #t) '(1 0 0)))
  (define joined (union a b))
  (define overlap (intersection a b))
  (define cut (difference a b))
  (check-true (close? (solid-volume joined) 12.0))
  (check-true (close? (solid-volume overlap) 4.0))
  (check-true (close? (solid-volume cut) 4.0))
  (for-each solid-close! (list a b joined overlap cut)))

(test-case "capsule works in arbitrary direction"
  (define value (capsule '(1 2 3) '(11 2 3) 1 #:segments 32))
  (define-values (minimum maximum) (solid-bounds value))
  (check-true (close? (point3-x minimum) 0.0))
  (check-true (close? (point3-y minimum) 1.0))
  (check-true (close? (point3-z minimum) 2.0))
  (check-true (close? (point3-x maximum) 12.0))
  (check-true (close? (point3-y maximum) 3.0))
  (check-true (close? (point3-z maximum) 4.0))
  (check-true (< 34 (solid-volume value) 36))
  (solid-close! value))

(test-case "hull, trim, refinement, gap, and winding queries"
  (define base (cube 2 #:center? #t))
  (define shifted (translate base '(4 0 0)))
  (define hulled (hull base shifted))
  (define half (trim-by-plane base '(1 0 0) 0))
  (define refined (refine base 2))
  (check-true (close? (solid-volume hulled) 24.0))
  (check-true (close? (solid-volume half) 4.0))
  (check-true (> (solid-num-triangles refined) (solid-num-triangles base)))
  (check-true (close? (solid-min-gap base shifted 10) 2.0))
  (check-equal? (solid-winding-number base '(0 0 0)) 1)
  (check-equal? (solid-winding-number base '(10 0 0)) 0)
  (for-each solid-close! (list base shifted hulled half refined)))

(test-case "binary STL has the specified size and triangle count"
  (define value (capsule '(0 0 0) '(0 0 10) 1 #:segments 24))
  (define triangle-count (solid-num-triangles value))
  (define data (solid->stl-bytes value))
  (check-equal? (bytes-length data) (+ 84 (* 50 triangle-count)))
  (check-equal? (integer-bytes->integer data #f #f 80 84) triangle-count)
  (solid-close! value))

(test-case "ASCII STL contains one facet per triangle"
  (define value (cube 1))
  (define text (bytes->string/utf-8 (solid->stl-bytes value #:format 'ascii)))
  (check-true (regexp-match? #rx"^solid manifold" text))
  (check-equal? (length (regexp-match* #rx"facet normal" text)) 12)
  (solid-close! value))

(test-case "with-units normalizes geometry and scales STL output"
  (define mm-cube (u:with-units u:millimetre (u:cube 10)))
  (define inch-cube (u:with-units u:inch (u:cube (u:millimetres 10))))
  (check-true
   (u:with-units u:millimetre
     (close? (u:solid-volume mm-cube) 1000.0 1e-8)))
  (check-true
   (u:with-units u:millimetre
     (close? (u:solid-volume inch-cube) 1000.0 1e-8)))
  (define data (u:with-units u:millimetre (u:solid->stl-bytes mm-cube)))
  ;; First vertex X begins after header/count/normal at byte 96. It must be in
  ;; millimetres, so all coordinates lie between 0 and 10 rather than 0.01.
  (define coordinates
    (for/list ([offset (in-list '(96 100 104 108 112 116 120 124 128))])
      (floating-point-bytes->real data #f offset (+ offset 4))))
  (check-true (andmap (lambda (x) (<= 0 x 10)) coordinates))
  (u:solid-close! mm-cube)
  (u:solid-close! inch-cube))

(test-case "physical constructors require a unit context"
  (check-exn exn:fail? (lambda () (u:cube 10))))

(test-case "circular segment contexts nest and explicit arguments override"
  (define explicit (sphere 1 #:segments 16))
  (define scoped (with-circular-segments 16 (sphere 1)))
  (define overridden
    (with-circular-segments 32 (sphere 1 #:segments 16)))
  (check-equal? (solid-num-triangles scoped) (solid-num-triangles explicit))
  (check-equal? (solid-num-triangles overridden)
                (solid-num-triangles explicit))
  (check-equal? (current-circular-segments) 0)
  (check-exn exn:fail? (lambda () (with-circular-segments 2 (sphere 1))))
  (for-each solid-close! (list explicit scoped overridden)))

(test-case "circular segment context is shared by the units facade"
  (define scoped
    (u:with-units u:millimetre
      (u:with-circular-segments 20 (u:capsule '(0 0 0) '(0 0 10) 1))))
  (define explicit
    (u:with-units u:millimetre
      (u:capsule '(0 0 0) '(0 0 10) 1 #:segments 20)))
  (check-equal? (u:solid-num-triangles scoped)
                (u:solid-num-triangles explicit))
  (u:solid-close! scoped)
  (u:solid-close! explicit))

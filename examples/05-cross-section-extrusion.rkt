#lang racket/base

(require "../manifold/units.rkt"
         "support.rkt")

(provide run)

(define (run)
  (with-units millimetre
    (with-circular-segments 40
      (define body (square 42 24 #:center? #t))
      (define end (circle 12))
      (define centered-a (cross-section-translate end '(-21 0)))
      (define centered-b (cross-section-translate end '(21 0)))
      (define outline (cross-section-union body centered-a centered-b))
      (define hole (circle 4 #:segments 32))
      (define hole-a (cross-section-translate hole '(-21 0)))
      (define hole-b (cross-section-translate hole '(21 0)))
      (define drilled (cross-section-difference outline hole-a hole-b))
      (define softened
        (cross-section-offset drilled 1.2 #:join 'round #:segments 24))
      (define solid (extrude softened 5))
      (printf "05-cross-section-extrusion: area ~a; volume ~a; contours ~a\n"
              (cross-section-area softened) (solid-volume solid)
              (cross-section-num-contours softened))
      (emit-obj "05-cross-section-extrusion" (solid->obj-string solid))
      (emit-stl "05-cross-section-extrusion" solid)
      (for-each cross-section-close!
                (list body end centered-a centered-b outline hole hole-a hole-b
                      drilled softened))
      (solid-close! solid))))

(module+ main (run))

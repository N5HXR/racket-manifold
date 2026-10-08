#lang racket/base

(require "../manifold/main.rkt"
         "support.rkt")

(provide run)

(define (run)
  ;; A tetrahedron supplied directly as indexed double-precision mesh data.
  (define source
    (mesh (vector (point3 0 0 0) (point3 24 0 0)
                  (point3 0 24 0) (point3 0 0 24))
          (vector (triangle 0 2 1) (triangle 0 1 3)
                  (triangle 1 2 3) (triangle 2 0 3))))
  (define solid (mesh->solid source))
  (define refined (refine solid 2))
  (define extracted (solid->mesh refined))
  (define hits (solid-ray-cast refined '(-1 2 2) '(30 2 2)))
  (printf "07-mesh-round-trip: ~a input triangles -> ~a refined triangles; ~a ray hits\n"
          (vector-length (mesh-triangles source))
          (vector-length (mesh-triangles extracted))
          (length hits))
  (printf "  extracted ~a vertices\n" (vector-length (mesh-vertices extracted)))
  (emit-obj "07-mesh-round-trip" (solid->obj-string refined))
  (solid-close! solid)
  (solid-close! refined))

(module+ main (run))

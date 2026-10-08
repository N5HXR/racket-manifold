#lang racket/base

(require ffi/unsafe
         "library.rkt")

(provide (all-defined-out))

(define-syntax-rule (define-raw racket-name c-name type)
  (define racket-name (get-ffi-obj c-name manifold-lib type)))

;; Opaque native object pointers.
(define _manifold _pointer)
(define _manifold-vec _pointer)
(define _meshgl64 _pointer)
(define _manifold-box _pointer)

;; POD types passed by value by libmanifoldc.
(define-cstruct _manifold-vec2 ([x _double] [y _double]))
(define-cstruct _manifold-vec3 ([x _double] [y _double] [z _double]))
(define-cstruct _manifold-ivec3 ([x _int] [y _int] [z _int]))

;; Version and allocation.
(define-raw raw-manifold-version "manifold_version"
  (_fun _pointer -> _void))
(define-raw raw-alloc-manifold "manifold_alloc_manifold"
  (_fun -> _manifold))
(define-raw raw-delete-manifold "manifold_delete_manifold"
  (_fun _manifold -> _void))
(define-raw raw-alloc-manifold-vec "manifold_alloc_manifold_vec"
  (_fun -> _manifold-vec))
(define-raw raw-delete-manifold-vec "manifold_delete_manifold_vec"
  (_fun _manifold-vec -> _void))
(define-raw raw-alloc-meshgl64 "manifold_alloc_meshgl64"
  (_fun -> _meshgl64))
(define-raw raw-delete-meshgl64 "manifold_delete_meshgl64"
  (_fun _meshgl64 -> _void))
(define-raw raw-alloc-box "manifold_alloc_box"
  (_fun -> _manifold-box))
(define-raw raw-delete-box "manifold_delete_box"
  (_fun _manifold-box -> _void))

;; Constructors.
(define-raw raw-empty "manifold_empty"
  (_fun _manifold -> _manifold))
(define-raw raw-copy "manifold_copy"
  (_fun _manifold _manifold -> _manifold))
(define-raw raw-tetrahedron "manifold_tetrahedron"
  (_fun _manifold -> _manifold))
(define-raw raw-cube "manifold_cube"
  (_fun _manifold _double _double _double _int -> _manifold))
(define-raw raw-cylinder "manifold_cylinder"
  (_fun _manifold _double _double _double _int _int -> _manifold))
(define-raw raw-sphere "manifold_sphere"
  (_fun _manifold _double _int -> _manifold))

;; Manifold vectors and Boolean operations.
(define-raw raw-manifold-empty-vec "manifold_manifold_empty_vec"
  (_fun _manifold-vec -> _manifold-vec))
(define-raw raw-manifold-vec-push-back "manifold_manifold_vec_push_back"
  (_fun _manifold-vec _manifold -> _void))
(define-raw raw-batch-boolean "manifold_batch_boolean"
  (_fun _manifold _manifold-vec _int -> _manifold))
(define-raw raw-union "manifold_union"
  (_fun _manifold _manifold _manifold -> _manifold))
(define-raw raw-difference "manifold_difference"
  (_fun _manifold _manifold _manifold -> _manifold))
(define-raw raw-intersection "manifold_intersection"
  (_fun _manifold _manifold _manifold -> _manifold))
(define-raw raw-trim-by-plane "manifold_trim_by_plane"
  (_fun _manifold _manifold _double _double _double _double -> _manifold))
(define-raw raw-minkowski-sum "manifold_minkowski_sum"
  (_fun _manifold _manifold _manifold -> _manifold))
(define-raw raw-minkowski-difference "manifold_minkowski_difference"
  (_fun _manifold _manifold _manifold -> _manifold))
(define-raw raw-hull "manifold_hull"
  (_fun _manifold _manifold -> _manifold))
(define-raw raw-batch-hull "manifold_batch_hull"
  (_fun _manifold _manifold-vec -> _manifold))

;; Transformations. The 3x4 transform is column-major, matching linalg.h.
(define-raw raw-translate "manifold_translate"
  (_fun _manifold _manifold _double _double _double -> _manifold))
(define-raw raw-rotate "manifold_rotate"
  (_fun _manifold _manifold _double _double _double -> _manifold))
(define-raw raw-scale "manifold_scale"
  (_fun _manifold _manifold _double _double _double -> _manifold))
(define-raw raw-transform "manifold_transform"
  (_fun _manifold _manifold
        _double _double _double
        _double _double _double
        _double _double _double
        _double _double _double
        -> _manifold))
(define-raw raw-mirror "manifold_mirror"
  (_fun _manifold _manifold _double _double _double -> _manifold))
(define-raw raw-refine "manifold_refine"
  (_fun _manifold _manifold _int -> _manifold))
(define-raw raw-refine-to-length "manifold_refine_to_length"
  (_fun _manifold _manifold _double -> _manifold))
(define-raw raw-refine-to-tolerance "manifold_refine_to_tolerance"
  (_fun _manifold _manifold _double -> _manifold))
(define-raw raw-simplify "manifold_simplify"
  (_fun _manifold _manifold _double -> _manifold))

;; Queries and realization.
(define-raw raw-status "manifold_status" (_fun _manifold -> _int))
(define-raw raw-is-empty "manifold_is_empty" (_fun _manifold -> _int))
(define-raw raw-num-vert "manifold_num_vert" (_fun _manifold -> _size))
(define-raw raw-num-edge "manifold_num_edge" (_fun _manifold -> _size))
(define-raw raw-num-tri "manifold_num_tri" (_fun _manifold -> _size))
(define-raw raw-genus "manifold_genus" (_fun _manifold -> _int))
(define-raw raw-surface-area "manifold_surface_area" (_fun _manifold -> _double))
(define-raw raw-volume "manifold_volume" (_fun _manifold -> _double))
(define-raw raw-min-gap "manifold_min_gap"
  (_fun _manifold _manifold _double -> _double))
(define-raw raw-winding-number "manifold_winding_number"
  (_fun _manifold _double _double _double -> _int))
(define-raw raw-bounding-box "manifold_bounding_box"
  (_fun _manifold-box _manifold -> _manifold-box))
(define-raw raw-box-min "manifold_box_min"
  (_fun _manifold-box -> _manifold-vec3))
(define-raw raw-box-max "manifold_box_max"
  (_fun _manifold-box -> _manifold-vec3))

;; Double-precision mesh extraction.
(define-raw raw-get-meshgl64 "manifold_get_meshgl64"
  (_fun _meshgl64 _manifold -> _meshgl64))
(define-raw raw-meshgl64-num-prop "manifold_meshgl64_num_prop"
  (_fun _meshgl64 -> _size))
(define-raw raw-meshgl64-num-vert "manifold_meshgl64_num_vert"
  (_fun _meshgl64 -> _size))
(define-raw raw-meshgl64-num-tri "manifold_meshgl64_num_tri"
  (_fun _meshgl64 -> _size))
(define-raw raw-meshgl64-vert-properties "manifold_meshgl64_vert_properties"
  (_fun _pointer _meshgl64 -> _pointer))
(define-raw raw-meshgl64-tri-verts "manifold_meshgl64_tri_verts"
  (_fun _pointer _meshgl64 -> _pointer))

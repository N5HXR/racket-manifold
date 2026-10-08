#lang racket/base

(require ffi/unsafe
         racket/include
         racket/list
         racket/match
         racket/sequence
         "private/library.rkt"
         "private/raw.rkt"
         (prefix-in c: "private/generated-unsafe.rkt"))

(provide
 manifold-version
 manifold-library-path
 (struct-out vec2)
 (struct-out vec3)
 (struct-out ivec3)
 manifold-handle?
 meshgl64-handle?
 native-handle-closed?
 native-handle-close!
 manifold-empty
 manifold-copy
 manifold-tetrahedron
 manifold-cube
 manifold-cylinder
 manifold-sphere
 manifold-union
 manifold-difference
 manifold-intersection
 manifold-batch-boolean
 manifold-hull
 manifold-batch-hull
 manifold-trim-by-plane
 manifold-minkowski-sum
 manifold-minkowski-difference
 manifold-translate
 manifold-rotate
 manifold-scale
 manifold-transform
 manifold-mirror
 manifold-refine
 manifold-refine-to-length
 manifold-refine-to-tolerance
 manifold-simplify
 manifold-status
 manifold-empty?
 manifold-num-vert
 manifold-num-edge
 manifold-num-tri
 manifold-genus
 manifold-surface-area
 manifold-volume
 manifold-min-gap
 manifold-winding-number
 manifold-bounds
 manifold-get-meshgl64
 meshgl64-num-prop
 meshgl64-num-vert
 meshgl64-num-tri
 meshgl64-vertices
 meshgl64-triangles)

(struct vec2 (x y) #:transparent)
(struct vec3 (x y z) #:transparent)
(struct ivec3 (x y z) #:transparent)

;; The mutable pointer is the single source of truth for liveness. Finalization
;; and explicit close both pass through the same idempotent operation.
(struct native-handle (ptr deleter kind) #:mutable)
(struct manifold-handle native-handle ())
(struct meshgl64-handle native-handle ())

(define (native-handle-closed? value)
  (not (native-handle-ptr value)))

(define (native-handle-close! value)
  (unless (native-handle? value)
    (raise-argument-error 'native-handle-close! "native-handle?" value))
  (define ptr (native-handle-ptr value))
  (when ptr
    ;; Mark closed first. If a native destructor were ever to fail, a finalizer
    ;; must not attempt the same destruction again.
    (set-native-handle-ptr! value #f)
    ((native-handle-deleter value) ptr))
  (void))

(define (own pointer deleter constructor kind)
  (unless pointer
    (error 'manifold "native allocator returned NULL for ~a" kind))
  (define value (constructor pointer deleter kind))
  (register-finalizer value native-handle-close!)
  value)

(define (handle-pointer who expected? value)
  (unless (expected? value)
    (raise-argument-error who
                          (if (eq? expected? manifold-handle?)
                              "manifold-handle?"
                              "meshgl64-handle?")
                          value))
  (or (native-handle-ptr value)
      (raise-arguments-error who "native value has been closed" "value" value)))

(define (construct-manifold who constructor . args)
  (define storage (raw-alloc-manifold))
  (define result (apply constructor storage args))
  (unless result
    (error who "native constructor returned NULL"))
  (own result raw-delete-manifold manifold-handle 'manifold))

(define (construct-meshgl64 who constructor . args)
  (define storage (raw-alloc-meshgl64))
  (define result (apply constructor storage args))
  (unless result
    (error who "native constructor returned NULL"))
  (own result raw-delete-meshgl64 meshgl64-handle 'meshgl64))

(define (->double who value)
  (unless (and (real? value) (rational? value))
    (raise-argument-error who "finite-real?" value))
  (define result (exact->inexact value))
  (unless (rational? result)
    (raise-arguments-error who
                           "value is outside the finite double range"
                           "value" value))
  result)

(define (manifold-version)
  (define memory (malloc (* 3 (ctype-sizeof _int)) 'atomic))
  (raw-manifold-version memory)
  (for/list ([i (in-range 3)]) (ptr-ref memory _int i)))

(define (manifold-empty)
  (construct-manifold 'manifold-empty raw-empty))

(define (manifold-copy value)
  (construct-manifold 'manifold-copy raw-copy
                      (handle-pointer 'manifold-copy manifold-handle? value)))

(define (manifold-tetrahedron)
  (construct-manifold 'manifold-tetrahedron raw-tetrahedron))

(define (manifold-cube x y z [center? #f])
  (construct-manifold 'manifold-cube raw-cube
                      (->double 'manifold-cube x)
                      (->double 'manifold-cube y)
                      (->double 'manifold-cube z)
                      (if center? 1 0)))

(define (manifold-cylinder height radius-low radius-high
                            [circular-segments 0] [center? #f])
  (construct-manifold 'manifold-cylinder raw-cylinder
                      (->double 'manifold-cylinder height)
                      (->double 'manifold-cylinder radius-low)
                      (->double 'manifold-cylinder radius-high)
                      circular-segments
                      (if center? 1 0)))

(define (manifold-sphere radius [circular-segments 0])
  (construct-manifold 'manifold-sphere raw-sphere
                      (->double 'manifold-sphere radius) circular-segments))

(define (binary-manifold who native a b)
  (construct-manifold who native
                      (handle-pointer who manifold-handle? a)
                      (handle-pointer who manifold-handle? b)))

(define (manifold-union a b) (binary-manifold 'manifold-union raw-union a b))
(define (manifold-difference a b)
  (binary-manifold 'manifold-difference raw-difference a b))
(define (manifold-intersection a b)
  (binary-manifold 'manifold-intersection raw-intersection a b))

(define op->integer (hash 'add 0 'subtract 1 'intersect 2))

(define (manifold-batch-boolean values operation)
  (unless (and (list? values) (pair? values))
    (raise-argument-error 'manifold-batch-boolean
                          "nonempty-list-of-manifold-handles" values))
  (define op
    (hash-ref op->integer operation
              (lambda ()
                (raise-argument-error 'manifold-batch-boolean
                                      "(or/c 'add 'subtract 'intersect)"
                                      operation))))
  (define storage (raw-alloc-manifold-vec))
  (raw-manifold-empty-vec storage)
  (dynamic-wind
    void
    (lambda ()
      (for ([value (in-list values)])
        (raw-manifold-vec-push-back
         storage
         (handle-pointer 'manifold-batch-boolean manifold-handle? value)))
      (construct-manifold 'manifold-batch-boolean raw-batch-boolean storage op))
    (lambda () (raw-delete-manifold-vec storage))))

(define (with-manifold-vector who values procedure)
  (unless (and (list? values) (pair? values))
    (raise-argument-error who "nonempty-list-of-manifold-handles" values))
  (define storage (raw-alloc-manifold-vec))
  (raw-manifold-empty-vec storage)
  (dynamic-wind
    void
    (lambda ()
      (for ([value (in-list values)])
        (raw-manifold-vec-push-back
         storage (handle-pointer who manifold-handle? value)))
      (procedure storage))
    (lambda () (raw-delete-manifold-vec storage))))

(define (manifold-hull value)
  (construct-manifold 'manifold-hull raw-hull
                      (handle-pointer 'manifold-hull manifold-handle? value)))

(define (manifold-batch-hull values)
  (with-manifold-vector
   'manifold-batch-hull values
   (lambda (storage)
     (construct-manifold 'manifold-batch-hull raw-batch-hull storage))))

(define (manifold-trim-by-plane value nx ny nz offset)
  (construct-manifold
   'manifold-trim-by-plane raw-trim-by-plane
   (handle-pointer 'manifold-trim-by-plane manifold-handle? value)
   (->double 'manifold-trim-by-plane nx)
   (->double 'manifold-trim-by-plane ny)
   (->double 'manifold-trim-by-plane nz)
   (->double 'manifold-trim-by-plane offset)))

(define (manifold-minkowski-sum a b)
  (binary-manifold 'manifold-minkowski-sum raw-minkowski-sum a b))

(define (manifold-minkowski-difference a b)
  (binary-manifold 'manifold-minkowski-difference raw-minkowski-difference a b))

(define (manifold-translate value x y z)
  (construct-manifold 'manifold-translate raw-translate
                      (handle-pointer 'manifold-translate manifold-handle? value)
                      (->double 'manifold-translate x)
                      (->double 'manifold-translate y)
                      (->double 'manifold-translate z)))

(define (manifold-rotate value x y z)
  (construct-manifold 'manifold-rotate raw-rotate
                      (handle-pointer 'manifold-rotate manifold-handle? value)
                      (->double 'manifold-rotate x)
                      (->double 'manifold-rotate y)
                      (->double 'manifold-rotate z)))

(define (manifold-scale value x y z)
  (construct-manifold 'manifold-scale raw-scale
                      (handle-pointer 'manifold-scale manifold-handle? value)
                      (->double 'manifold-scale x)
                      (->double 'manifold-scale y)
                      (->double 'manifold-scale z)))

(define (manifold-transform value
                            x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4)
  (construct-manifold
   'manifold-transform raw-transform
   (handle-pointer 'manifold-transform manifold-handle? value)
   (->double 'manifold-transform x1) (->double 'manifold-transform y1)
   (->double 'manifold-transform z1) (->double 'manifold-transform x2)
   (->double 'manifold-transform y2) (->double 'manifold-transform z2)
   (->double 'manifold-transform x3) (->double 'manifold-transform y3)
   (->double 'manifold-transform z3) (->double 'manifold-transform x4)
   (->double 'manifold-transform y4) (->double 'manifold-transform z4)))

(define (manifold-mirror value nx ny nz)
  (construct-manifold 'manifold-mirror raw-mirror
                      (handle-pointer 'manifold-mirror manifold-handle? value)
                      (->double 'manifold-mirror nx)
                      (->double 'manifold-mirror ny)
                      (->double 'manifold-mirror nz)))

(define (manifold-refine value n)
  (unless (exact-nonnegative-integer? n)
    (raise-argument-error 'manifold-refine "exact-nonnegative-integer?" n))
  (construct-manifold 'manifold-refine raw-refine
                      (handle-pointer 'manifold-refine manifold-handle? value)
                      n))

(define (manifold-refine-to-length value length)
  (construct-manifold
   'manifold-refine-to-length raw-refine-to-length
   (handle-pointer 'manifold-refine-to-length manifold-handle? value)
   (->double 'manifold-refine-to-length length)))

(define (manifold-refine-to-tolerance value tolerance)
  (construct-manifold
   'manifold-refine-to-tolerance raw-refine-to-tolerance
   (handle-pointer 'manifold-refine-to-tolerance manifold-handle? value)
   (->double 'manifold-refine-to-tolerance tolerance)))

(define (manifold-simplify value tolerance)
  (construct-manifold
   'manifold-simplify raw-simplify
   (handle-pointer 'manifold-simplify manifold-handle? value)
   (->double 'manifold-simplify tolerance)))

(define status-symbols
  '#(no-error non-finite-vertex not-manifold vertex-index-out-of-bounds
     properties-wrong-length missing-position-properties
     merge-vectors-different-lengths merge-index-out-of-bounds
     transform-wrong-length run-index-wrong-length face-id-wrong-length
     invalid-construction result-too-large invalid-tangents cancelled))

(define (manifold-status value)
  (define code
    (raw-status (handle-pointer 'manifold-status manifold-handle? value)))
  (if (< -1 code (vector-length status-symbols))
      (vector-ref status-symbols code)
      `(unknown-status ,code)))

(define (manifold-empty? value)
  (not (zero? (raw-is-empty
               (handle-pointer 'manifold-empty? manifold-handle? value)))))

(define-syntax-rule (define-manifold-query name raw-name)
  (define (name value)
    (raw-name (handle-pointer 'name manifold-handle? value))))

(define-manifold-query manifold-num-vert raw-num-vert)
(define-manifold-query manifold-num-edge raw-num-edge)
(define-manifold-query manifold-num-tri raw-num-tri)
(define-manifold-query manifold-genus raw-genus)
(define-manifold-query manifold-surface-area raw-surface-area)
(define-manifold-query manifold-volume raw-volume)

(define (manifold-min-gap value other search-length)
  (raw-min-gap (handle-pointer 'manifold-min-gap manifold-handle? value)
               (handle-pointer 'manifold-min-gap manifold-handle? other)
               (->double 'manifold-min-gap search-length)))

(define (manifold-winding-number value x y z)
  (raw-winding-number
   (handle-pointer 'manifold-winding-number manifold-handle? value)
   (->double 'manifold-winding-number x)
   (->double 'manifold-winding-number y)
   (->double 'manifold-winding-number z)))

(define (c-vec3->vec3 value)
  (vec3 (manifold-vec3-x value)
        (manifold-vec3-y value)
        (manifold-vec3-z value)))

(define (manifold-bounds value)
  (define storage (raw-alloc-box))
  (define result
    (raw-bounding-box storage
                      (handle-pointer 'manifold-bounds manifold-handle? value)))
  (unless result (error 'manifold-bounds "native call returned NULL"))
  (dynamic-wind
    void
    (lambda ()
      (values (c-vec3->vec3 (raw-box-min result))
              (c-vec3->vec3 (raw-box-max result))))
    (lambda () (raw-delete-box result))))

(define (manifold-get-meshgl64 value)
  (construct-meshgl64
   'manifold-get-meshgl64 raw-get-meshgl64
   (handle-pointer 'manifold-get-meshgl64 manifold-handle? value)))

(define-syntax-rule (define-mesh-query name raw-name)
  (define (name value)
    (raw-name (handle-pointer 'name meshgl64-handle? value))))

(define-mesh-query meshgl64-num-prop raw-meshgl64-num-prop)
(define-mesh-query meshgl64-num-vert raw-meshgl64-num-vert)
(define-mesh-query meshgl64-num-tri raw-meshgl64-num-tri)

(define (meshgl64-vertices value)
  (define ptr (handle-pointer 'meshgl64-vertices meshgl64-handle? value))
  (define props (raw-meshgl64-num-prop ptr))
  (define count (raw-meshgl64-num-vert ptr))
  (when (< props 3)
    (error 'meshgl64-vertices
           "mesh has ~a properties per vertex; at least 3 required" props))
  (define memory (malloc (* count props (ctype-sizeof _double)) 'atomic))
  (raw-meshgl64-vert-properties memory ptr)
  (for/vector #:length count ([vertex (in-range count)])
    (define base (* vertex props))
    (vec3 (ptr-ref memory _double base)
          (ptr-ref memory _double (+ base 1))
          (ptr-ref memory _double (+ base 2)))))

(define (meshgl64-triangles value)
  (define ptr (handle-pointer 'meshgl64-triangles meshgl64-handle? value))
  (define count (raw-meshgl64-num-tri ptr))
  (define memory (malloc (* count 3 (ctype-sizeof _uint64)) 'atomic))
  (raw-meshgl64-tri-verts memory ptr)
  (for/vector #:length count ([triangle (in-range count)])
    (define base (* triangle 3))
    (ivec3 (ptr-ref memory _uint64 base)
           (ptr-ref memory _uint64 (+ base 1))
           (ptr-ref memory _uint64 (+ base 2)))))

;; Complete managed C API coverage is kept in a lexical include so it can share
;; ownership machinery above without exposing raw pointers between modules.
(include "private/managed-extra.inc")

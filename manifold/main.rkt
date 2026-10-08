#lang racket/base

(require racket/list
         racket/include
         racket/match
         racket/port
         (prefix-in ll: "low-level.rkt")
         "private/stl.rkt")

(provide
 manifold-version
 (rename-out [ll:manifold-library-path manifold-library-path])
 (struct-out point3)
 (struct-out triangle)
 (struct-out mesh)
 solid?
 solid-close!
 solid-closed?
 exn:fail:manifold?
 exn:fail:manifold-operation
 exn:fail:manifold-status
 current-circular-segments
 with-circular-segments
 empty-solid
 tetrahedron
 cube
 cylinder
 sphere
 capsule
 between
 union
 difference
 intersection
 hull
 trim-by-plane
 minkowski-sum
 minkowski-difference
 translate
 rotate
 scale
 transform
 mirror
 refine
 refine-to-length
 refine-to-tolerance
 simplify
 solid-empty?
 solid-num-vertices
 solid-num-edges
 solid-num-triangles
 solid-genus
 solid-surface-area
 solid-volume
 solid-min-gap
 solid-winding-number
 solid-bounds
 solid->mesh
 write-stl
 solid->stl-bytes)

(define manifold-version ll:manifold-version)
(struct point3 (x y z) #:transparent)
(struct triangle (a b c) #:transparent)
(struct mesh (vertices triangles) #:transparent)
(struct solid (handle))
(struct exn:fail:manifold exn:fail (operation status) #:transparent)

;; A Racket parameter is preferable to Manifold's process-wide quality global:
;; it nests cleanly, restores automatically, and is local to the current
;; parameterization. An explicit #:segments argument still wins at the call.
(define current-circular-segments
  (make-parameter
   0
   (lambda (value)
     (unless (and (exact-nonnegative-integer? value)
                  (or (zero? value) (>= value 3)))
       (raise-argument-error 'current-circular-segments
                             "(or/c 0 (integer-in 3 +inf.0))" value))
     value)))

(define-syntax-rule (with-circular-segments count body ...)
  (parameterize ([current-circular-segments count]) body ...))

(define (solid-close! value)
  (unless (solid? value) (raise-argument-error 'solid-close! "solid?" value))
  (ll:native-handle-close! (solid-handle value)))

(define (solid-closed? value)
  (unless (solid? value) (raise-argument-error 'solid-closed? "solid?" value))
  (ll:native-handle-closed? (solid-handle value)))

(define (raise-status who status)
  (raise
   (exn:fail:manifold
    (format "~a: Manifold operation failed with status ~a" who status)
    (current-continuation-marks)
    who status)))

(define (checked-solid who handle)
  (define status (ll:manifold-status handle))
  (unless (eq? status 'no-error)
    (ll:native-handle-close! handle)
    (raise-status who status))
  (solid handle))

(define (solid-handle/checked who value)
  (unless (solid? value) (raise-argument-error who "solid?" value))
  (when (solid-closed? value)
    (raise-arguments-error who "solid has been closed" "solid" value))
  (solid-handle value))

(define (finite-real who value)
  (unless (and (real? value) (rational? value))
    (raise-argument-error who "finite-real?" value))
  value)

(define (positive-real who value)
  (finite-real who value)
  (unless (positive? value)
    (raise-argument-error who "positive-real?" value))
  value)

(define (segments-value who value)
  (unless (exact-nonnegative-integer? value)
    (raise-argument-error who "exact-nonnegative-integer?" value))
  value)

(define (point-like->point3 who value)
  (define coordinates
    (cond
      [(point3? value) (list (point3-x value) (point3-y value) (point3-z value))]
      [(and (list? value) (= (length value) 3)) value]
      [(and (vector? value) (= (vector-length value) 3)) (vector->list value)]
      [else (raise-argument-error who "(or/c point3? three-element-list? three-element-vector?)" value)]))
  (for ([coordinate (in-list coordinates)]) (finite-real who coordinate))
  (apply point3 coordinates))

(define (empty-solid)
  (checked-solid 'empty-solid (ll:manifold-empty)))

(define (tetrahedron)
  (checked-solid 'tetrahedron (ll:manifold-tetrahedron)))

(define (cube x [y x] [z x] #:center? [center? #f])
  (positive-real 'cube x)
  (positive-real 'cube y)
  (positive-real 'cube z)
  (checked-solid 'cube (ll:manifold-cube x y z center?)))

(define (cylinder height radius
                  #:top-radius [top-radius radius]
                  #:segments [segments (current-circular-segments)]
                  #:center? [center? #f])
  (positive-real 'cylinder height)
  (positive-real 'cylinder radius)
  (positive-real 'cylinder top-radius)
  (segments-value 'cylinder segments)
  (checked-solid
   'cylinder
   (ll:manifold-cylinder height radius top-radius segments center?)))

(define (sphere radius #:segments [segments (current-circular-segments)])
  (positive-real 'sphere radius)
  (segments-value 'sphere segments)
  (checked-solid 'sphere (ll:manifold-sphere radius segments)))

(define (solid-list who values minimum)
  (unless (and (list? values)
               (>= (length values) minimum)
               (andmap solid? values))
    (raise-argument-error who
                          (format "list of at least ~a solids" minimum)
                          values))
  values)

(define (union first . rest)
  (define values (solid-list 'union (cons first rest) 1))
  (if (null? rest)
      (checked-solid 'union (ll:manifold-copy (solid-handle/checked 'union first)))
      (checked-solid
       'union
       (ll:manifold-batch-boolean
        (map (lambda (value) (solid-handle/checked 'union value)) values)
        'add))))

(define (intersection first . rest)
  (define values (solid-list 'intersection (cons first rest) 1))
  (if (null? rest)
      (checked-solid 'intersection
                     (ll:manifold-copy
                      (solid-handle/checked 'intersection first)))
      (checked-solid
       'intersection
       (ll:manifold-batch-boolean
        (map (lambda (value) (solid-handle/checked 'intersection value)) values)
        'intersect))))

(define (difference base . cutters)
  (solid-handle/checked 'difference base)
  (unless (andmap solid? cutters)
    (raise-argument-error 'difference "solids after the base solid" cutters))
  (cond
    [(null? cutters)
     (checked-solid 'difference
                    (ll:manifold-copy (solid-handle/checked 'difference base)))]
    [(null? (cdr cutters))
     (checked-solid
      'difference
      (ll:manifold-difference
       (solid-handle/checked 'difference base)
       (solid-handle/checked 'difference (car cutters))))]
    [else
     (define cutter (apply union cutters))
     (dynamic-wind
       void
       (lambda () (difference base cutter))
       (lambda () (solid-close! cutter))) ]))

(define (hull first . rest)
  (define values (solid-list 'hull (cons first rest) 1))
  (checked-solid
   'hull
   (if (null? rest)
       (ll:manifold-hull (solid-handle/checked 'hull first))
       (ll:manifold-batch-hull
        (map (lambda (value) (solid-handle/checked 'hull value)) values)))))

(define (trim-by-plane value normal offset)
  (define p (point-like->point3 'trim-by-plane normal))
  (finite-real 'trim-by-plane offset)
  (when (and (zero? (point3-x p)) (zero? (point3-y p)) (zero? (point3-z p)))
    (raise-argument-error 'trim-by-plane "nonzero 3D normal" normal))
  (checked-solid
   'trim-by-plane
   (ll:manifold-trim-by-plane
    (solid-handle/checked 'trim-by-plane value)
    (point3-x p) (point3-y p) (point3-z p) offset)))

(define (minkowski-sum a b)
  (checked-solid
   'minkowski-sum
   (ll:manifold-minkowski-sum
    (solid-handle/checked 'minkowski-sum a)
    (solid-handle/checked 'minkowski-sum b))))

(define (minkowski-difference a b)
  (checked-solid
   'minkowski-difference
   (ll:manifold-minkowski-difference
    (solid-handle/checked 'minkowski-difference a)
    (solid-handle/checked 'minkowski-difference b))))

(define (translate value offset [y #f] [z #f])
  (define p
    (if (and y z)
        (point-like->point3 'translate (list offset y z))
        (point-like->point3 'translate offset)))
  (checked-solid
   'translate
   (ll:manifold-translate (solid-handle/checked 'translate value)
                          (point3-x p) (point3-y p) (point3-z p))))

(define (rotate value x [y 0] [z 0])
  (for ([angle (in-list (list x y z))]) (finite-real 'rotate angle))
  (checked-solid
   'rotate
   (ll:manifold-rotate (solid-handle/checked 'rotate value) x y z)))

(define (scale value x [y x] [z x])
  (for ([factor (in-list (list x y z))]) (finite-real 'scale factor))
  (checked-solid
   'scale
   (ll:manifold-scale (solid-handle/checked 'scale value) x y z)))

(define (transform value matrix)
  (unless (and (list? matrix)
               (= (length matrix) 3)
               (andmap (lambda (row) (and (list? row) (= (length row) 4))) matrix))
    (raise-argument-error 'transform "three lists of four finite reals" matrix))
  (define flat (apply append matrix))
  (for ([item (in-list flat)]) (finite-real 'transform item))
  ;; Public matrices are conventional row-major. The C ABI accepts columns.
  (match-define (list (list r00 r01 r02 tx)
                      (list r10 r11 r12 ty)
                      (list r20 r21 r22 tz)) matrix)
  (checked-solid
   'transform
   (ll:manifold-transform
    (solid-handle/checked 'transform value)
    r00 r10 r20 r01 r11 r21 r02 r12 r22 tx ty tz)))

(define (mirror value normal)
  (define p (point-like->point3 'mirror normal))
  (when (and (zero? (point3-x p)) (zero? (point3-y p)) (zero? (point3-z p)))
    (raise-argument-error 'mirror "nonzero 3D vector" normal))
  (checked-solid
   'mirror
   (ll:manifold-mirror (solid-handle/checked 'mirror value)
                       (point3-x p) (point3-y p) (point3-z p))))

(define (refine value count)
  (checked-solid
   'refine
   (ll:manifold-refine (solid-handle/checked 'refine value) count)))

(define (refine-to-length value length)
  (positive-real 'refine-to-length length)
  (checked-solid
   'refine-to-length
   (ll:manifold-refine-to-length
    (solid-handle/checked 'refine-to-length value) length)))

(define (refine-to-tolerance value tolerance)
  (positive-real 'refine-to-tolerance tolerance)
  (checked-solid
   'refine-to-tolerance
   (ll:manifold-refine-to-tolerance
    (solid-handle/checked 'refine-to-tolerance value) tolerance)))

(define (simplify value [tolerance 0])
  (finite-real 'simplify tolerance)
  (when (negative? tolerance)
    (raise-argument-error 'simplify "nonnegative-real?" tolerance))
  (checked-solid
   'simplify
   (ll:manifold-simplify (solid-handle/checked 'simplify value) tolerance)))

(define (p- a b)
  (point3 (- (point3-x a) (point3-x b))
          (- (point3-y a) (point3-y b))
          (- (point3-z a) (point3-z b))))

(define (dot a b)
  (+ (* (point3-x a) (point3-x b))
     (* (point3-y a) (point3-y b))
     (* (point3-z a) (point3-z b))))

(define (cross a b)
  (point3 (- (* (point3-y a) (point3-z b)) (* (point3-z a) (point3-y b)))
          (- (* (point3-z a) (point3-x b)) (* (point3-x a) (point3-z b)))
          (- (* (point3-x a) (point3-y b)) (* (point3-y a) (point3-x b)))))

(define (magnitude p) (sqrt (dot p p)))

(define (normalize who p)
  (define length (magnitude p))
  (when (zero? length) (raise-argument-error who "noncoincident points" p))
  (point3 (/ (point3-x p) length)
          (/ (point3-y p) length)
          (/ (point3-z p) length)))

(define (between a b radius #:segments [segments (current-circular-segments)])
  (define start (point-like->point3 'between a))
  (define end (point-like->point3 'between b))
  (positive-real 'between radius)
  (segments-value 'between segments)
  (define delta (p- end start))
  (define length (magnitude delta))
  (when (zero? length)
    (raise-arguments-error 'between "endpoints must be distinct"
                           "start" a "end" b))
  (define z-axis (normalize 'between delta))
  (define reference
    (if (< (abs (point3-z z-axis)) 9/10)
        (point3 0 0 1)
        (point3 0 1 0)))
  (define x-axis (normalize 'between (cross reference z-axis)))
  (define y-axis (cross z-axis x-axis))
  (define primitive (cylinder length radius #:segments segments))
  (dynamic-wind
    void
    (lambda ()
      (transform
       primitive
       (list (list (point3-x x-axis) (point3-x y-axis) (point3-x z-axis)
                   (point3-x start))
             (list (point3-y x-axis) (point3-y y-axis) (point3-y z-axis)
                   (point3-y start))
             (list (point3-z x-axis) (point3-z y-axis) (point3-z z-axis)
                   (point3-z start)))))
    (lambda () (solid-close! primitive))))

(define (capsule a b radius #:segments [segments (current-circular-segments)])
  (define start (point-like->point3 'capsule a))
  (define end (point-like->point3 'capsule b))
  (positive-real 'capsule radius)
  (segments-value 'capsule segments)
  (if (equal? start end)
      (translate (sphere radius #:segments segments) start)
      (let* ([shaft (between start end radius #:segments segments)]
             [left (translate (sphere radius #:segments segments) start)]
             [right (translate (sphere radius #:segments segments) end)])
        (dynamic-wind
          void
          (lambda () (union shaft left right))
          (lambda ()
            (solid-close! shaft)
            (solid-close! left)
            (solid-close! right))))))

(define (query who procedure value)
  (procedure (solid-handle/checked who value)))

(define (solid-empty? value) (query 'solid-empty? ll:manifold-empty? value))
(define (solid-num-vertices value)
  (query 'solid-num-vertices ll:manifold-num-vert value))
(define (solid-num-edges value)
  (query 'solid-num-edges ll:manifold-num-edge value))
(define (solid-num-triangles value)
  (query 'solid-num-triangles ll:manifold-num-tri value))
(define (solid-genus value) (query 'solid-genus ll:manifold-genus value))
(define (solid-surface-area value)
  (query 'solid-surface-area ll:manifold-surface-area value))
(define (solid-volume value) (query 'solid-volume ll:manifold-volume value))

(define (solid-min-gap value other search-length)
  (positive-real 'solid-min-gap search-length)
  (ll:manifold-min-gap (solid-handle/checked 'solid-min-gap value)
                       (solid-handle/checked 'solid-min-gap other)
                       search-length))

(define (solid-winding-number value point)
  (define p (point-like->point3 'solid-winding-number point))
  (ll:manifold-winding-number
   (solid-handle/checked 'solid-winding-number value)
   (point3-x p) (point3-y p) (point3-z p)))

(define (solid-bounds value)
  (define-values (minimum maximum)
    (ll:manifold-bounds (solid-handle/checked 'solid-bounds value)))
  (values (point3 (ll:vec3-x minimum) (ll:vec3-y minimum) (ll:vec3-z minimum))
          (point3 (ll:vec3-x maximum) (ll:vec3-y maximum) (ll:vec3-z maximum))))

(define (solid->mesh value)
  (define native
    (ll:manifold-get-meshgl64 (solid-handle/checked 'solid->mesh value)))
  (dynamic-wind
    void
    (lambda ()
      (mesh
       (for/vector ([vertex (in-vector (ll:meshgl64-vertices native))])
         (point3 (ll:vec3-x vertex) (ll:vec3-y vertex) (ll:vec3-z vertex)))
       (for/vector ([face (in-vector (ll:meshgl64-triangles native))])
         (triangle (ll:ivec3-x face) (ll:ivec3-y face) (ll:ivec3-z face)))))
    (lambda () (ll:native-handle-close! native))))

(define (write-stl value destination #:format [format 'binary] #:name [name "manifold"])
  (write-mesh-stl (solid->mesh value) destination #:format format #:name name))

(define (solid->stl-bytes value #:format [format 'binary] #:name [name "manifold"])
  (mesh->stl-bytes (solid->mesh value) #:format format #:name name))

;; Additional version-1 functional operations share the private solid and
;; status machinery above without exposing native handles between modules.
(include "private/layer2-extra.inc")

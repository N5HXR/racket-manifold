;; Managed coverage for the remainder of manifoldc.h. This file is included
;; lexically by ../low-level.rkt and therefore intentionally has no #lang.

(provide
 (struct-out ray-hit)
 manifold-vector-handle? cross-section-handle? cross-section-vector-handle?
 simple-polygon-handle? polygons-handle? meshgl-handle? box-handle?
 rect-handle? triangulation-handle? execution-context-handle?
 simple-polygon polygons simple-polygon-length polygons-length
 polygons-simple-length simple-polygon-point polygons-simple polygons-point
 box box-min box-max box-dimensions box-center box-scale box-contains-point?
 box-contains-box? box-include-point! box-union box-transform box-translate
 box-multiply box-overlaps-point? box-overlaps-box? box-finite?
 rect rect-min rect-max rect-dimensions rect-center rect-scale
 rect-contains-point? rect-contains-rect? rect-include-point! rect-union
 rect-transform rect-translate rect-multiply rect-overlaps-rect? rect-empty?
 rect-finite?
 cross-section-empty cross-section-copy cross-section-of-simple-polygon
 manifold-vector manifold-vector-reserve! manifold-vector-length
 manifold-vector-ref manifold-vector-set! manifold-vector-add!
 cross-section-vector cross-section-vector-reserve! cross-section-vector-length
 cross-section-vector-ref cross-section-vector-set! cross-section-vector-add!
 cross-section-of-polygons cross-section-even-odd-simple-polygon
 cross-section-even-odd-polygons cross-section-square cross-section-circle
 cross-section-decompose cross-section-boolean cross-section-batch-boolean
 cross-section-union cross-section-difference cross-section-intersection
 cross-section-hull cross-section-batch-hull
 cross-section-hull-simple-polygon cross-section-hull-polygons
 cross-section-translate cross-section-rotate cross-section-scale
 cross-section-mirror cross-section-transform cross-section-warp
 cross-section-simplify cross-section-offset cross-section-area
 cross-section-num-vertices cross-section-num-contours cross-section-empty?
 cross-section-bounds cross-section->polygons
 manifold-boolean manifold-split manifold-split-by-plane manifold-slice manifold-project
 manifold-hull-points manifold-warp manifold-smooth-by-normals
 manifold-of-meshgl manifold-of-meshgl64 manifold-extrude manifold-revolve
 manifold-compose manifold-decompose manifold-as-original manifold-with-context
 manifold-num-properties manifold-epsilon manifold-num-property-vertices
 manifold-circular-segments manifold-original-id manifold-reserve-ids
 manifold-set-properties manifold-calculate-curvature
 manifold-calculate-normals manifold-ray-cast
 execution-context execution-context-cancel! execution-context-cancelled?
 execution-context-progress execution-context-level-set
 execution-context-level-set-sequential execution-context-of-meshgl
 execution-context-of-meshgl64 manifold-level-set
 manifold-level-set-sequential
 meshgl meshgl-with-tangents meshgl-copy meshgl-merge manifold-get-meshgl
 mesh-options mesh-options? meshgl-with-options
 manifold-get-meshgl-with-normals
 meshgl64 meshgl64-with-tangents meshgl64-copy meshgl64-merge
 meshgl64-with-options
 manifold-get-meshgl64-with-normals
 meshgl-num-properties meshgl-num-vertices meshgl-num-triangles
 meshgl-vertex-properties meshgl-triangle-vertices meshgl-merge-from-vertices
 meshgl-merge-to-vertices meshgl-run-indices meshgl-run-original-ids
 meshgl-run-transforms meshgl-face-ids meshgl-halfedge-tangents
 meshgl-tolerance meshgl-run-flags meshgl-num-runs meshgl-backside?
 meshgl-has-normals?
 meshgl64-vertex-properties meshgl64-triangle-vertices
 meshgl64-merge-from-vertices meshgl64-merge-to-vertices
 meshgl64-run-indices meshgl64-run-original-ids meshgl64-run-transforms
 meshgl64-face-ids meshgl64-halfedge-tangents meshgl64-tolerance
 meshgl64-run-flags meshgl64-num-runs meshgl64-backside?
 meshgl64-has-normals?
 triangulate triangulation-num-triangles triangulation-triangles
 manifold-read-obj manifold-write-obj meshgl64-read-obj meshgl64-write-obj
 set-relative-precision! relative-precision set-min-circular-angle!
 set-min-circular-edge-length! set-circular-segments!
 reset-circular-defaults!)

(struct ray-hit (face-id distance position normal) #:transparent)
(struct mesh-options (run-indices run-original-ids merge-from-vertices
                                  merge-to-vertices halfedge-tangents)
  #:transparent)
(struct manifold-vector-handle native-handle ())
(struct cross-section-handle native-handle ())
(struct cross-section-vector-handle native-handle ())
(struct ray-hit-vector-handle native-handle ())
(struct simple-polygon-handle native-handle ())
(struct polygons-handle native-handle ())
(struct meshgl-handle native-handle ())
(struct box-handle native-handle ())
(struct rect-handle native-handle ())
(struct triangulation-handle native-handle ())
(struct execution-context-handle native-handle ())

(define (checked-pointer who predicate description value)
  (unless (predicate value) (raise-argument-error who description value))
  (or (native-handle-ptr value)
      (raise-arguments-error who "native value has been closed" "value" value)))

(define (make-owned who allocator deleter wrapper native . args)
  (define storage (allocator))
  (unless storage (error who "native allocator returned NULL"))
  (define result (apply native storage args))
  (unless result
    (deleter storage)
    (error who "native constructor returned NULL"))
  (own result deleter wrapper who))

(define (mptr who v) (handle-pointer who manifold-handle? v))
(define (m64ptr who v) (handle-pointer who meshgl64-handle? v))
(define (mvptr who v) (checked-pointer who manifold-vector-handle? "manifold-vector-handle?" v))
(define (csptr who v) (checked-pointer who cross-section-handle? "cross-section-handle?" v))
(define (csvptr who v) (checked-pointer who cross-section-vector-handle? "cross-section-vector-handle?" v))
(define (spptr who v) (checked-pointer who simple-polygon-handle? "simple-polygon-handle?" v))
(define (pptr who v) (checked-pointer who polygons-handle? "polygons-handle?" v))
(define (meshptr who v) (checked-pointer who meshgl-handle? "meshgl-handle?" v))
(define (boxptr who v) (checked-pointer who box-handle? "box-handle?" v))
(define (rectptr who v) (checked-pointer who rect-handle? "rect-handle?" v))
(define (triptr who v) (checked-pointer who triangulation-handle? "triangulation-handle?" v))
(define (ecptr who v) (checked-pointer who execution-context-handle? "execution-context-handle?" v))

(define (bool v) (not (zero? v)))
(define (c-vec2->vec2 v) (vec2 (c:manifold-vec2-x v) (c:manifold-vec2-y v)))
(define (c3->vec3 v) (vec3 (c:manifold-vec3-x v) (c:manifold-vec3-y v) (c:manifold-vec3-z v)))
(define (vec2-like who v)
  (match v
    [(vec2 x y) (values (->double who x) (->double who y))]
    [(list x y) (values (->double who x) (->double who y))]
    [(vector x y) (values (->double who x) (->double who y))]
    [_ (raise-argument-error who "(or/c vec2? (list/c real? real?) (vector/c real? real?))" v)]))
(define (vec3-like who v)
  (match v
    [(vec3 x y z) (values (->double who x) (->double who y) (->double who z))]
    [(list x y z) (values (->double who x) (->double who y) (->double who z))]
    [(vector x y z) (values (->double who x) (->double who y) (->double who z))]
    [_ (raise-argument-error who "3D point or vector" v)]))

(define (list->c-array who xs ctype convert)
  (unless (list? xs) (raise-argument-error who "list?" xs))
  (define mem (malloc (* (length xs) (ctype-sizeof ctype)) 'atomic))
  (for ([x (in-list xs)] [i (in-naturals)]) (ptr-set! mem ctype i (convert x)))
  (values mem (length xs)))

(define (simple-polygon points)
  (define-values (mem count)
    (list->c-array 'simple-polygon points c:_manifold-vec2
      (lambda (p) (define-values (x y) (vec2-like 'simple-polygon p))
        (c:make-manifold-vec2 x y))))
  (make-owned 'simple-polygon c:manifold_alloc_simple_polygon
              c:manifold_delete_simple_polygon simple-polygon-handle
              c:manifold_simple_polygon mem count))

(define (polygons simple-polygons)
  (define-values (mem count)
    (list->c-array 'polygons simple-polygons _pointer
      (lambda (p) (spptr 'polygons p))))
  (make-owned 'polygons c:manifold_alloc_polygons c:manifold_delete_polygons
              polygons-handle c:manifold_polygons mem count))
(define (simple-polygon-length p) (c:manifold_simple_polygon_length (spptr 'simple-polygon-length p)))
(define (polygons-length p) (c:manifold_polygons_length (pptr 'polygons-length p)))
(define (polygons-simple-length p i) (c:manifold_polygons_simple_length (pptr 'polygons-simple-length p) i))
(define (simple-polygon-point p i) (c-vec2->vec2 (c:manifold_simple_polygon_get_point (spptr 'simple-polygon-point p) i)))
(define (polygons-simple p i)
  (make-owned 'polygons-simple c:manifold_alloc_simple_polygon
              c:manifold_delete_simple_polygon simple-polygon-handle
              c:manifold_polygons_get_simple (pptr 'polygons-simple p) i))
(define (polygons-point p si pi) (c-vec2->vec2 (c:manifold_polygons_get_point (pptr 'polygons-point p) si pi)))

;; Rectangles and boxes are owned objects too; mutating include-point calls are
;; explicit while all other operations return fresh managed values.
(define (rect x1 y1 x2 y2)
  (make-owned 'rect c:manifold_alloc_rect c:manifold_delete_rect rect-handle
              c:manifold_rect (->double 'rect x1) (->double 'rect y1)
              (->double 'rect x2) (->double 'rect y2)))
(define-syntax-rule (define-rect-vquery name native)
  (define (name r) (c-vec2->vec2 (native (rectptr 'name r)))))
(define-rect-vquery rect-min c:manifold_rect_min)
(define-rect-vquery rect-max c:manifold_rect_max)
(define-rect-vquery rect-dimensions c:manifold_rect_dimensions)
(define-rect-vquery rect-center c:manifold_rect_center)
(define (rect-scale r) (c:manifold_rect_scale (rectptr 'rect-scale r)))
(define (rect-contains-point? r x y) (bool (c:manifold_rect_contains_pt (rectptr 'rect-contains-point? r) (->double 'rect-contains-point? x) (->double 'rect-contains-point? y))))
(define (rect-contains-rect? a b) (bool (c:manifold_rect_contains_rect (rectptr 'rect-contains-rect? a) (rectptr 'rect-contains-rect? b))))
(define (rect-include-point! r x y) (c:manifold_rect_include_pt (rectptr 'rect-include-point! r) (->double 'rect-include-point! x) (->double 'rect-include-point! y)))
(define (make-rect-result who native . args) (apply make-owned who c:manifold_alloc_rect c:manifold_delete_rect rect-handle native args))
(define (rect-union a b) (make-rect-result 'rect-union c:manifold_rect_union (rectptr 'rect-union a) (rectptr 'rect-union b)))
(define (rect-transform r x1 y1 x2 y2 x3 y3) (apply make-rect-result 'rect-transform c:manifold_rect_transform (rectptr 'rect-transform r) (map (lambda (x) (->double 'rect-transform x)) (list x1 y1 x2 y2 x3 y3))))
(define (rect-translate r x y) (make-rect-result 'rect-translate c:manifold_rect_translate (rectptr 'rect-translate r) (->double 'rect-translate x) (->double 'rect-translate y)))
(define (rect-multiply r x y) (make-rect-result 'rect-multiply c:manifold_rect_mul (rectptr 'rect-multiply r) (->double 'rect-multiply x) (->double 'rect-multiply y)))
(define (rect-overlaps-rect? a b) (bool (c:manifold_rect_does_overlap_rect (rectptr 'rect-overlaps-rect? a) (rectptr 'rect-overlaps-rect? b))))
(define (rect-empty? r) (bool (c:manifold_rect_is_empty (rectptr 'rect-empty? r))))
(define (rect-finite? r) (bool (c:manifold_rect_is_finite (rectptr 'rect-finite? r))))

(define (box x1 y1 z1 x2 y2 z2)
  (apply make-owned 'box c:manifold_alloc_box c:manifold_delete_box box-handle c:manifold_box
         (map (lambda (x) (->double 'box x)) (list x1 y1 z1 x2 y2 z2))))
(define-syntax-rule (define-box-vquery name native)
  (define (name b) (c3->vec3 (native (boxptr 'name b)))))
(define-box-vquery box-min c:manifold_box_min)
(define-box-vquery box-max c:manifold_box_max)
(define-box-vquery box-dimensions c:manifold_box_dimensions)
(define-box-vquery box-center c:manifold_box_center)
(define (box-scale b) (c:manifold_box_scale (boxptr 'box-scale b)))
(define (box-contains-point? b x y z) (bool (c:manifold_box_contains_pt (boxptr 'box-contains-point? b) (->double 'box-contains-point? x) (->double 'box-contains-point? y) (->double 'box-contains-point? z))))
(define (box-contains-box? a b) (bool (c:manifold_box_contains_box (boxptr 'box-contains-box? a) (boxptr 'box-contains-box? b))))
(define (box-include-point! b x y z) (c:manifold_box_include_pt (boxptr 'box-include-point! b) (->double 'box-include-point! x) (->double 'box-include-point! y) (->double 'box-include-point! z)))
(define (make-box-result who native . args) (apply make-owned who c:manifold_alloc_box c:manifold_delete_box box-handle native args))
(define (box-union a b) (make-box-result 'box-union c:manifold_box_union (boxptr 'box-union a) (boxptr 'box-union b)))
(define (box-transform b . xs) (unless (= (length xs) 12) (raise-arguments-error 'box-transform "expected twelve matrix components" "components" xs)) (apply make-box-result 'box-transform c:manifold_box_transform (boxptr 'box-transform b) (map (lambda (x) (->double 'box-transform x)) xs)))
(define (box-translate b x y z) (make-box-result 'box-translate c:manifold_box_translate (boxptr 'box-translate b) (->double 'box-translate x) (->double 'box-translate y) (->double 'box-translate z)))
(define (box-multiply b x y z) (make-box-result 'box-multiply c:manifold_box_mul (boxptr 'box-multiply b) (->double 'box-multiply x) (->double 'box-multiply y) (->double 'box-multiply z)))
(define (box-overlaps-point? b x y z) (bool (c:manifold_box_does_overlap_pt (boxptr 'box-overlaps-point? b) (->double 'box-overlaps-point? x) (->double 'box-overlaps-point? y) (->double 'box-overlaps-point? z))))
(define (box-overlaps-box? a b) (bool (c:manifold_box_does_overlap_box (boxptr 'box-overlaps-box? a) (boxptr 'box-overlaps-box? b))))
(define (box-finite? b) (bool (c:manifold_box_is_finite (boxptr 'box-finite? b))))

;; Cross sections -----------------------------------------------------------
(define (make-cs who native . args)
  (apply make-owned who c:manifold_alloc_cross_section
         c:manifold_delete_cross_section cross-section-handle native args))
(define (cross-section-empty) (make-cs 'cross-section-empty c:manifold_cross_section_empty))
(define (cross-section-copy cs) (make-cs 'cross-section-copy c:manifold_cross_section_copy (csptr 'cross-section-copy cs)))
(define (cross-section-of-simple-polygon p) (make-cs 'cross-section-of-simple-polygon c:manifold_cross_section_of_simple_polygon (spptr 'cross-section-of-simple-polygon p)))
(define (cross-section-of-polygons p) (make-cs 'cross-section-of-polygons c:manifold_cross_section_of_polygons (pptr 'cross-section-of-polygons p)))
(define (cross-section-even-odd-simple-polygon p) (make-cs 'cross-section-even-odd-simple-polygon c:manifold_cross_section_even_odd_simple_polygon (spptr 'cross-section-even-odd-simple-polygon p)))
(define (cross-section-even-odd-polygons p) (make-cs 'cross-section-even-odd-polygons c:manifold_cross_section_even_odd_polygons (pptr 'cross-section-even-odd-polygons p)))
(define (cross-section-square x y [center? #f]) (make-cs 'cross-section-square c:manifold_cross_section_square (->double 'cross-section-square x) (->double 'cross-section-square y) (if center? 1 0)))
(define (cross-section-circle radius [segments 0]) (make-cs 'cross-section-circle c:manifold_cross_section_circle (->double 'cross-section-circle radius) segments))

(define (with-cs-vector who css proc [allow-empty? #f])
  (unless (and (list? css) (or allow-empty? (pair? css)))
    (raise-argument-error who (if allow-empty? "list-of-cross-section-handles" "nonempty-list-of-cross-section-handles") css))
  (define storage (c:manifold_alloc_cross_section_vec))
  (c:manifold_cross_section_empty_vec storage)
  (dynamic-wind void
    (lambda ()
      (for ([cs (in-list css)])
        (c:manifold_cross_section_vec_push_back storage (csptr who cs)))
      (proc storage))
    (lambda () (c:manifold_delete_cross_section_vec storage))))

(define (cross-section-vector->list who vector-ptr)
  (dynamic-wind void
    (lambda ()
      (for/list ([i (in-range (c:manifold_cross_section_vec_length vector-ptr))])
        (make-cs who c:manifold_cross_section_vec_get vector-ptr i)))
    (lambda () (c:manifold_delete_cross_section_vec vector-ptr))))

(define (cross-section-vector [size 0])
  (make-owned 'cross-section-vector c:manifold_alloc_cross_section_vec
              c:manifold_delete_cross_section_vec cross-section-vector-handle
              c:manifold_cross_section_vec size))
(define (cross-section-vector-reserve! v n) (c:manifold_cross_section_vec_reserve (csvptr 'cross-section-vector-reserve! v) n))
(define (cross-section-vector-length v) (c:manifold_cross_section_vec_length (csvptr 'cross-section-vector-length v)))
(define (cross-section-vector-ref v i) (make-cs 'cross-section-vector-ref c:manifold_cross_section_vec_get (csvptr 'cross-section-vector-ref v) i))
(define (cross-section-vector-set! v i cs) (c:manifold_cross_section_vec_set (csvptr 'cross-section-vector-set! v) i (csptr 'cross-section-vector-set! cs)))
(define (cross-section-vector-add! v cs) (c:manifold_cross_section_vec_push_back (csvptr 'cross-section-vector-add! v) (csptr 'cross-section-vector-add! cs)))

(define (cross-section-decompose cs)
  (define storage (c:manifold_alloc_cross_section_vec))
  (define result (c:manifold_cross_section_decompose storage (csptr 'cross-section-decompose cs)))
  (unless result (c:manifold_delete_cross_section_vec storage) (error 'cross-section-decompose "native call returned NULL"))
  (cross-section-vector->list 'cross-section-decompose result))

(define (operation-code who op)
  (hash-ref op->integer op (lambda () (raise-argument-error who "(or/c 'add 'subtract 'intersect)" op))))
(define (cross-section-boolean a b op)
  (make-cs 'cross-section-boolean c:manifold_cross_section_boolean
           (csptr 'cross-section-boolean a) (csptr 'cross-section-boolean b)
           (operation-code 'cross-section-boolean op)))
(define (cross-section-batch-boolean css op)
  (with-cs-vector 'cross-section-batch-boolean css
    (lambda (v) (make-cs 'cross-section-batch-boolean c:manifold_cross_section_batch_boolean v (operation-code 'cross-section-batch-boolean op)))))
(define (cs-binary who native a b) (make-cs who native (csptr who a) (csptr who b)))
(define (cross-section-union a b) (cs-binary 'cross-section-union c:manifold_cross_section_union a b))
(define (cross-section-difference a b) (cs-binary 'cross-section-difference c:manifold_cross_section_difference a b))
(define (cross-section-intersection a b) (cs-binary 'cross-section-intersection c:manifold_cross_section_intersection a b))
(define (cross-section-hull cs) (make-cs 'cross-section-hull c:manifold_cross_section_hull (csptr 'cross-section-hull cs)))
(define (cross-section-batch-hull css) (with-cs-vector 'cross-section-batch-hull css (lambda (v) (make-cs 'cross-section-batch-hull c:manifold_cross_section_batch_hull v))))
(define (cross-section-hull-simple-polygon p) (make-cs 'cross-section-hull-simple-polygon c:manifold_cross_section_hull_simple_polygon (spptr 'cross-section-hull-simple-polygon p)))
(define (cross-section-hull-polygons p) (make-cs 'cross-section-hull-polygons c:manifold_cross_section_hull_polygons (pptr 'cross-section-hull-polygons p)))
(define (cross-section-translate cs x y) (make-cs 'cross-section-translate c:manifold_cross_section_translate (csptr 'cross-section-translate cs) (->double 'cross-section-translate x) (->double 'cross-section-translate y)))
(define (cross-section-rotate cs degrees) (make-cs 'cross-section-rotate c:manifold_cross_section_rotate (csptr 'cross-section-rotate cs) (->double 'cross-section-rotate degrees)))
(define (cross-section-scale cs x y) (make-cs 'cross-section-scale c:manifold_cross_section_scale (csptr 'cross-section-scale cs) (->double 'cross-section-scale x) (->double 'cross-section-scale y)))
(define (cross-section-mirror cs x y) (make-cs 'cross-section-mirror c:manifold_cross_section_mirror (csptr 'cross-section-mirror cs) (->double 'cross-section-mirror x) (->double 'cross-section-mirror y)))
(define (cross-section-transform cs x1 y1 x2 y2 x3 y3)
  (apply make-cs 'cross-section-transform c:manifold_cross_section_transform (csptr 'cross-section-transform cs)
         (map (lambda (x) (->double 'cross-section-transform x)) (list x1 y1 x2 y2 x3 y3))))
(define (cross-section-warp cs proc)
  (unless (procedure? proc) (raise-argument-error 'cross-section-warp "procedure?" proc))
  (define callback
    (lambda (x y ignored)
      (define-values (rx ry) (vec2-like 'cross-section-warp (proc x y)))
      (c:make-manifold-vec2 rx ry)))
  (make-cs 'cross-section-warp c:manifold_cross_section_warp_context
           (csptr 'cross-section-warp cs) callback #f))
(define (cross-section-simplify cs tolerance) (make-cs 'cross-section-simplify c:manifold_cross_section_simplify (csptr 'cross-section-simplify cs) (->double 'cross-section-simplify tolerance)))
(define join-codes (hash 'square 0 'round 1 'miter 2 'bevel 3))
(define (cross-section-offset cs delta join [miter-limit 2.0] [segments 0])
  (define code (hash-ref join-codes join (lambda () (raise-argument-error 'cross-section-offset "(or/c 'square 'round 'miter 'bevel)" join))))
  (make-cs 'cross-section-offset c:manifold_cross_section_offset (csptr 'cross-section-offset cs)
           (->double 'cross-section-offset delta) code (->double 'cross-section-offset miter-limit) segments))
(define (cross-section-area cs) (c:manifold_cross_section_area (csptr 'cross-section-area cs)))
(define (cross-section-num-vertices cs) (c:manifold_cross_section_num_vert (csptr 'cross-section-num-vertices cs)))
(define (cross-section-num-contours cs) (c:manifold_cross_section_num_contour (csptr 'cross-section-num-contours cs)))
(define (cross-section-empty? cs) (bool (c:manifold_cross_section_is_empty (csptr 'cross-section-empty? cs))))
(define (cross-section-bounds cs) (make-rect-result 'cross-section-bounds c:manifold_cross_section_bounds (csptr 'cross-section-bounds cs)))
(define (cross-section->polygons cs) (make-owned 'cross-section->polygons c:manifold_alloc_polygons c:manifold_delete_polygons polygons-handle c:manifold_cross_section_to_polygons (csptr 'cross-section->polygons cs)))

;; Remaining manifold operations -------------------------------------------
(define (owned-manifold-pointer who ptr)
  (unless ptr (error who "native constructor returned NULL"))
  (own ptr c:manifold_delete_manifold manifold-handle 'manifold))
(define (manifold-vector [size 0])
  (make-owned 'manifold-vector c:manifold_alloc_manifold_vec
              c:manifold_delete_manifold_vec manifold-vector-handle
              c:manifold_manifold_vec size))
(define (manifold-vector-reserve! v n) (c:manifold_manifold_vec_reserve (mvptr 'manifold-vector-reserve! v) n))
(define (manifold-vector-length v) (c:manifold_manifold_vec_length (mvptr 'manifold-vector-length v)))
(define (manifold-vector-ref v i) (construct-manifold 'manifold-vector-ref c:manifold_manifold_vec_get (mvptr 'manifold-vector-ref v) i))
(define (manifold-vector-set! v i m) (c:manifold_manifold_vec_set (mvptr 'manifold-vector-set! v) i (mptr 'manifold-vector-set! m)))
(define (manifold-vector-add! v m) (c:manifold_manifold_vec_push_back (mvptr 'manifold-vector-add! v) (mptr 'manifold-vector-add! m)))
(define (manifold-boolean a b op)
  (construct-manifold 'manifold-boolean c:manifold_boolean
                      (mptr 'manifold-boolean a) (mptr 'manifold-boolean b)
                      (operation-code 'manifold-boolean op)))
(define (manifold-split a b)
  (define first (c:manifold_alloc_manifold))
  (define second (c:manifold_alloc_manifold))
  (define pair (c:manifold_split first second (mptr 'manifold-split a) (mptr 'manifold-split b)))
  (values (owned-manifold-pointer 'manifold-split (c:manifold-pair-first pair))
          (owned-manifold-pointer 'manifold-split (c:manifold-pair-second pair))))
(define (manifold-split-by-plane m nx ny nz offset)
  (define first (c:manifold_alloc_manifold))
  (define second (c:manifold_alloc_manifold))
  (define pair (c:manifold_split_by_plane first second (mptr 'manifold-split-by-plane m)
                (->double 'manifold-split-by-plane nx) (->double 'manifold-split-by-plane ny)
                (->double 'manifold-split-by-plane nz) (->double 'manifold-split-by-plane offset)))
  (values (owned-manifold-pointer 'manifold-split-by-plane (c:manifold-pair-first pair))
          (owned-manifold-pointer 'manifold-split-by-plane (c:manifold-pair-second pair))))
(define (manifold-slice m height) (make-owned 'manifold-slice c:manifold_alloc_polygons c:manifold_delete_polygons polygons-handle c:manifold_slice (mptr 'manifold-slice m) (->double 'manifold-slice height)))
(define (manifold-project m) (make-owned 'manifold-project c:manifold_alloc_polygons c:manifold_delete_polygons polygons-handle c:manifold_project (mptr 'manifold-project m)))
(define (manifold-hull-points points)
  (define-values (mem count)
    (list->c-array 'manifold-hull-points points c:_manifold-vec3
      (lambda (p) (define-values (x y z) (vec3-like 'manifold-hull-points p)) (c:make-manifold-vec3 x y z))))
  (construct-manifold 'manifold-hull-points c:manifold_hull_pts mem count))
(define (manifold-warp m proc)
  (unless (procedure? proc) (raise-argument-error 'manifold-warp "procedure?" proc))
  (define callback (lambda (x y z ignored) (define-values (rx ry rz) (vec3-like 'manifold-warp (proc x y z))) (c:make-manifold-vec3 rx ry rz)))
  (construct-manifold 'manifold-warp c:manifold_warp (mptr 'manifold-warp m) callback #f))
(define (manifold-smooth-by-normals m normal-index) (construct-manifold 'manifold-smooth-by-normals c:manifold_smooth_by_normals (mptr 'manifold-smooth-by-normals m) normal-index))
(define (manifold-of-meshgl mesh) (construct-manifold 'manifold-of-meshgl c:manifold_of_meshgl (meshptr 'manifold-of-meshgl mesh)))
(define (manifold-of-meshgl64 mesh) (construct-manifold 'manifold-of-meshgl64 c:manifold_of_meshgl64 (m64ptr 'manifold-of-meshgl64 mesh)))
(define (manifold-extrude p height [slices 0] [twist 0] [scale-x 1] [scale-y scale-x])
  (construct-manifold 'manifold-extrude c:manifold_extrude (pptr 'manifold-extrude p)
    (->double 'manifold-extrude height) slices (->double 'manifold-extrude twist)
    (->double 'manifold-extrude scale-x) (->double 'manifold-extrude scale-y)))
(define (manifold-revolve p [segments 0] [degrees 360])
  (construct-manifold 'manifold-revolve c:manifold_revolve (pptr 'manifold-revolve p) segments (->double 'manifold-revolve degrees)))

(define (with-manifold-vector/full who values proc [allow-empty? #f])
  (unless (and (list? values) (or allow-empty? (pair? values))) (raise-argument-error who "list-of-manifold-handles" values))
  (define storage (c:manifold_alloc_manifold_vec))
  (c:manifold_manifold_empty_vec storage)
  (dynamic-wind void (lambda () (for ([m values]) (c:manifold_manifold_vec_push_back storage (mptr who m))) (proc storage))
    (lambda () (c:manifold_delete_manifold_vec storage))))
(define (manifold-compose values) (with-manifold-vector/full 'manifold-compose values (lambda (v) (construct-manifold 'manifold-compose c:manifold_compose v)) #t))
(define (manifold-decompose m)
  (define storage (c:manifold_alloc_manifold_vec))
  (define result (c:manifold_decompose storage (mptr 'manifold-decompose m)))
  (unless result (c:manifold_delete_manifold_vec storage) (error 'manifold-decompose "native call returned NULL"))
  (dynamic-wind void
    (lambda () (for/list ([i (in-range (c:manifold_manifold_vec_length result))])
      (construct-manifold 'manifold-decompose c:manifold_manifold_vec_get result i)))
    (lambda () (c:manifold_delete_manifold_vec result))))
(define (manifold-as-original m [id -1]) (construct-manifold 'manifold-as-original c:manifold_as_original (mptr 'manifold-as-original m) id))
(define (manifold-with-context m ec) (construct-manifold 'manifold-with-context c:manifold_with_context (mptr 'manifold-with-context m) (ecptr 'manifold-with-context ec)))
(define (manifold-num-properties m) (c:manifold_num_prop (mptr 'manifold-num-properties m)))
(define (manifold-epsilon m) (c:manifold_epsilon (mptr 'manifold-epsilon m)))
(define (manifold-num-property-vertices m) (c:manifold_num_prop_vert (mptr 'manifold-num-property-vertices m)))
(define (manifold-circular-segments radius) (c:manifold_get_circular_segments (->double 'manifold-circular-segments radius)))
(define (manifold-original-id m) (c:manifold_original_id (mptr 'manifold-original-id m)))
(define (manifold-reserve-ids n) (c:manifold_reserve_ids n))
(define (manifold-calculate-curvature m gaussian-index mean-index) (construct-manifold 'manifold-calculate-curvature c:manifold_calculate_curvature (mptr 'manifold-calculate-curvature m) gaussian-index mean-index))
(define (manifold-calculate-normals m normal-index min-sharp-angle) (construct-manifold 'manifold-calculate-normals c:manifold_calculate_normals (mptr 'manifold-calculate-normals m) normal-index (->double 'manifold-calculate-normals min-sharp-angle)))
(define (manifold-set-properties m count proc)
  (unless (procedure? proc) (raise-argument-error 'manifold-set-properties "procedure?" proc))
  (define old-count (manifold-num-properties m))
  (define callback
    (lambda (new position old ignored)
      (define result (proc (c3->vec3 position) (for/vector ([i (in-range old-count)]) (ptr-ref old _double i))))
      (unless (and (sequence? result) (= (sequence-length result) count))
        (raise-arguments-error 'manifold-set-properties "callback returned wrong number of properties" "expected" count "result" result))
      (for ([x result] [i (in-naturals)]) (ptr-set! new _double i (->double 'manifold-set-properties x)))))
  (construct-manifold 'manifold-set-properties c:manifold_set_properties (mptr 'manifold-set-properties m) count callback #f))

(define (manifold-ray-cast m origin end)
  (define-values (ox oy oz) (vec3-like 'manifold-ray-cast origin))
  (define-values (ex ey ez) (vec3-like 'manifold-ray-cast end))
  (define storage (c:manifold_alloc_ray_hit_vec))
  (define result (c:manifold_ray_cast storage (mptr 'manifold-ray-cast m) ox oy oz ex ey ez))
  (unless result (c:manifold_delete_ray_hit_vec storage) (error 'manifold-ray-cast "native call returned NULL"))
  (dynamic-wind void
    (lambda ()
      (for/list ([i (in-range (c:manifold_ray_hit_vec_length result))])
        (define hit (c:manifold_ray_hit_vec_get result i))
        (ray-hit (c:manifold-ray-hit-face-id hit) (c:manifold-ray-hit-distance hit)
                 (c3->vec3 (c:manifold-ray-hit-position hit))
                 (c3->vec3 (c:manifold-ray-hit-normal hit)))))
    (lambda () (c:manifold_delete_ray_hit_vec result))))

;; Execution contexts and callback-driven level sets ------------------------
(define (execution-context)
  (make-owned 'execution-context c:manifold_alloc_execution_context
              c:manifold_delete_execution_context execution-context-handle
              c:manifold_execution_context))
(define (execution-context-cancel! ec) (c:manifold_execution_context_cancel (ecptr 'execution-context-cancel! ec)))
(define (execution-context-cancelled? ec) (bool (c:manifold_execution_context_cancelled (ecptr 'execution-context-cancelled? ec))))
(define (execution-context-progress ec) (c:manifold_execution_context_progress (ecptr 'execution-context-progress ec)))
(define (sdf-callback who proc)
  (unless (procedure? proc) (raise-argument-error who "procedure?" proc))
  (lambda (x y z ignored) (->double who (proc x y z))))
(define (level-set* who native sdf bounds edge-length level tolerance [ec #f])
  (construct-manifold who native
    (if ec (ecptr who ec) #f)
    (sdf-callback who sdf) (boxptr who bounds)
    (->double who edge-length) (->double who level) (->double who tolerance) #f))
(define (manifold-level-set sdf bounds edge-length [level 0] [tolerance -1])
  ;; Sequential is the safe default for a callback into the Racket runtime.
  (construct-manifold 'manifold-level-set c:manifold_level_set_seq
    (sdf-callback 'manifold-level-set sdf) (boxptr 'manifold-level-set bounds)
    (->double 'manifold-level-set edge-length) (->double 'manifold-level-set level)
    (->double 'manifold-level-set tolerance) #f))
(define (manifold-level-set-sequential sdf bounds edge-length [level 0] [tolerance -1])
  (manifold-level-set sdf bounds edge-length level tolerance))
(define (execution-context-level-set ec sdf bounds edge-length [level 0] [tolerance -1])
  ;; Context-based parallel callbacks are exposed but must only be used where
  ;; the host Racket build permits callbacks from Manifold worker threads.
  (construct-manifold 'execution-context-level-set c:manifold_execution_context_level_set
    (ecptr 'execution-context-level-set ec) (sdf-callback 'execution-context-level-set sdf)
    (boxptr 'execution-context-level-set bounds) (->double 'execution-context-level-set edge-length)
    (->double 'execution-context-level-set level) (->double 'execution-context-level-set tolerance) #f))
(define (execution-context-level-set-sequential ec sdf bounds edge-length [level 0] [tolerance -1])
  (construct-manifold 'execution-context-level-set-sequential c:manifold_execution_context_level_set_seq
    (ecptr 'execution-context-level-set-sequential ec) (sdf-callback 'execution-context-level-set-sequential sdf)
    (boxptr 'execution-context-level-set-sequential bounds) (->double 'execution-context-level-set-sequential edge-length)
    (->double 'execution-context-level-set-sequential level) (->double 'execution-context-level-set-sequential tolerance) #f))
(define (execution-context-of-meshgl ec mesh) (construct-manifold 'execution-context-of-meshgl c:manifold_execution_context_of_meshgl (ecptr 'execution-context-of-meshgl ec) (meshptr 'execution-context-of-meshgl mesh)))
(define (execution-context-of-meshgl64 ec mesh) (construct-manifold 'execution-context-of-meshgl64 c:manifold_execution_context_of_meshgl64 (ecptr 'execution-context-of-meshgl64 ec) (m64ptr 'execution-context-of-meshgl64 mesh)))

;; Mesh construction and extraction ----------------------------------------
(define (sequence->flat-list who seq)
  (unless (sequence? seq) (raise-argument-error who "sequence?" seq))
  (apply append
    (for/list ([value seq])
      (if (or (list? value) (vector? value)) (sequence->list value) (list value)))))
(define (number-array who seq ctype convert)
  (define flat (sequence->flat-list who seq))
  (define mem (malloc (* (length flat) (ctype-sizeof ctype)) 'atomic))
  (for ([x flat] [i (in-naturals)]) (ptr-set! mem ctype i (convert x)))
  (values mem (length flat)))
(define (mesh-inputs who properties num-props triangles prop-type index-type)
  (unless (exact-positive-integer? num-props) (raise-argument-error who "exact-positive-integer?" num-props))
  (define-values (props props-length) (number-array who properties prop-type (lambda (x) (->double who x))))
  (unless (zero? (remainder props-length num-props)) (raise-arguments-error who "property count is not divisible by num-props" "count" props-length "num-props" num-props))
  (define-values (tris tri-length) (number-array who triangles index-type (lambda (x) (unless (exact-nonnegative-integer? x) (raise-argument-error who "exact-nonnegative-integer?" x)) x)))
  (unless (zero? (remainder tri-length 3)) (raise-arguments-error who "triangle index count is not divisible by three" "count" tri-length))
  (values props (/ props-length num-props) tris (/ tri-length 3)))
(define (make-mesh who native properties num-props triangles . tail)
  (define-values (props verts tris ntris) (mesh-inputs who properties num-props triangles _float _uint32))
  (apply make-owned who c:manifold_alloc_meshgl c:manifold_delete_meshgl meshgl-handle native props verts num-props tris ntris tail))
(define (make-mesh64 who native properties num-props triangles . tail)
  (define-values (props verts tris ntris) (mesh-inputs who properties num-props triangles _double _uint64))
  (apply construct-meshgl64 who native props verts num-props tris ntris tail))
(define (meshgl properties num-props triangles) (make-mesh 'meshgl c:manifold_meshgl properties num-props triangles))
(define (meshgl-with-tangents properties num-props triangles tangents)
  (define-values (mem count) (number-array 'meshgl-with-tangents tangents _float (lambda (x) (->double 'meshgl-with-tangents x))))
  (make-mesh 'meshgl-with-tangents c:manifold_meshgl_w_tangents properties num-props triangles mem))
(define (meshgl64 properties num-props triangles) (make-mesh64 'meshgl64 c:manifold_meshgl64 properties num-props triangles))
(define (meshgl64-with-tangents properties num-props triangles tangents)
  (define-values (mem count) (number-array 'meshgl64-with-tangents tangents _double (lambda (x) (->double 'meshgl64-with-tangents x))))
  (make-mesh64 'meshgl64-with-tangents c:manifold_meshgl64_w_tangents properties num-props triangles mem))

(define-cstruct _managed-mesh-options
  ([run-indices _pointer] [run-indices-length _size]
   [run-original-ids _pointer] [run-original-ids-length _size]
   [merge-from _pointer] [merge-to _pointer] [merge-length _size]
   [halfedge-tangents _pointer]))
(define (option-array who seq type convert)
  (if seq (number-array who seq type convert) (values #f 0)))
(define (mesh-options-pointer who options index-type tangent-type)
  (unless (mesh-options? options) (raise-argument-error who "mesh-options?" options))
  (define iconvert (lambda (x) (unless (exact-nonnegative-integer? x) (raise-argument-error who "exact-nonnegative-integer?" x)) x))
  (define-values (runs nruns) (option-array who (mesh-options-run-indices options) index-type iconvert))
  (define-values (originals noriginals) (option-array who (mesh-options-run-original-ids options) _uint32 iconvert))
  (define-values (from nfrom) (option-array who (mesh-options-merge-from-vertices options) index-type iconvert))
  (define-values (to nto) (option-array who (mesh-options-merge-to-vertices options) index-type iconvert))
  (unless (= nfrom nto) (raise-arguments-error who "merge vectors have different lengths" "from" nfrom "to" nto))
  (define-values (tangents ntangents) (option-array who (mesh-options-halfedge-tangents options) tangent-type (lambda (x) (->double who x))))
  (make-managed-mesh-options runs nruns originals noriginals from to nfrom tangents))
(define (meshgl-with-options properties num-props triangles options)
  (make-mesh 'meshgl-with-options c:manifold_meshgl_w_options properties num-props triangles (mesh-options-pointer 'meshgl-with-options options _uint32 _float)))
(define (meshgl64-with-options properties num-props triangles options)
  (make-mesh64 'meshgl64-with-options c:manifold_meshgl64_w_options properties num-props triangles (mesh-options-pointer 'meshgl64-with-options options _uint64 _double)))
(define (meshgl-copy mesh) (make-owned 'meshgl-copy c:manifold_alloc_meshgl c:manifold_delete_meshgl meshgl-handle c:manifold_meshgl_copy (meshptr 'meshgl-copy mesh)))
(define (meshgl-merge mesh) (make-owned 'meshgl-merge c:manifold_alloc_meshgl c:manifold_delete_meshgl meshgl-handle c:manifold_meshgl_merge (meshptr 'meshgl-merge mesh)))
(define (meshgl64-copy mesh) (construct-meshgl64 'meshgl64-copy c:manifold_meshgl64_copy (m64ptr 'meshgl64-copy mesh)))
(define (meshgl64-merge mesh) (construct-meshgl64 'meshgl64-merge c:manifold_meshgl64_merge (m64ptr 'meshgl64-merge mesh)))
(define (manifold-get-meshgl m) (make-owned 'manifold-get-meshgl c:manifold_alloc_meshgl c:manifold_delete_meshgl meshgl-handle c:manifold_get_meshgl (mptr 'manifold-get-meshgl m)))
(define (manifold-get-meshgl-with-normals m index) (make-owned 'manifold-get-meshgl-with-normals c:manifold_alloc_meshgl c:manifold_delete_meshgl meshgl-handle c:manifold_get_meshgl_w_normals (mptr 'manifold-get-meshgl-with-normals m) index))
(define (manifold-get-meshgl64-with-normals m index) (construct-meshgl64 'manifold-get-meshgl64-with-normals c:manifold_get_meshgl64_w_normals (mptr 'manifold-get-meshgl64-with-normals m) index))

(define-syntax-rule (define-mesh-scalar name ptr native)
  (define (name mesh) (native (ptr 'name mesh))))
(define-mesh-scalar meshgl-num-properties meshptr c:manifold_meshgl_num_prop)
(define-mesh-scalar meshgl-num-vertices meshptr c:manifold_meshgl_num_vert)
(define-mesh-scalar meshgl-num-triangles meshptr c:manifold_meshgl_num_tri)
(define (copy-native-array who mesh ptr length-native data-native ctype)
  (define native-ptr (ptr who mesh))
  (define length (length-native native-ptr))
  (define mem (malloc (* length (ctype-sizeof ctype)) 'atomic))
  (data-native mem native-ptr)
  (for/vector #:length length ([i (in-range length)]) (ptr-ref mem ctype i)))
(define-syntax-rule (define-mesh-array name ptr len get type)
  (define (name mesh) (copy-native-array 'name mesh ptr len get type)))
(define-mesh-array meshgl-vertex-properties meshptr c:manifold_meshgl_vert_properties_length c:manifold_meshgl_vert_properties _float)
(define-mesh-array meshgl-triangle-vertices meshptr c:manifold_meshgl_tri_length c:manifold_meshgl_tri_verts _uint32)
(define-mesh-array meshgl-merge-from-vertices meshptr c:manifold_meshgl_merge_length c:manifold_meshgl_merge_from_vert _uint32)
(define-mesh-array meshgl-merge-to-vertices meshptr c:manifold_meshgl_merge_length c:manifold_meshgl_merge_to_vert _uint32)
(define-mesh-array meshgl-run-indices meshptr c:manifold_meshgl_run_index_length c:manifold_meshgl_run_index _uint32)
(define-mesh-array meshgl-run-original-ids meshptr c:manifold_meshgl_run_original_id_length c:manifold_meshgl_run_original_id _uint32)
(define-mesh-array meshgl-run-transforms meshptr c:manifold_meshgl_run_transform_length c:manifold_meshgl_run_transform _float)
(define-mesh-array meshgl-face-ids meshptr c:manifold_meshgl_face_id_length c:manifold_meshgl_face_id _uint32)
(define-mesh-array meshgl-halfedge-tangents meshptr c:manifold_meshgl_tangent_length c:manifold_meshgl_halfedge_tangent _float)
(define (meshgl-tolerance mesh) (c:manifold_meshgl_tolerance (meshptr 'meshgl-tolerance mesh)))
(define-mesh-array meshgl-run-flags meshptr c:manifold_meshgl_run_flags_length c:manifold_meshgl_run_flags _uint8)
(define (meshgl-num-runs mesh) (c:manifold_meshgl_num_run (meshptr 'meshgl-num-runs mesh)))
(define (meshgl-backside? mesh run) (bool (c:manifold_meshgl_backside (meshptr 'meshgl-backside? mesh) run)))
(define (meshgl-has-normals? mesh run) (bool (c:manifold_meshgl_has_normals (meshptr 'meshgl-has-normals? mesh) run)))

(define-mesh-array meshgl64-vertex-properties m64ptr c:manifold_meshgl64_vert_properties_length c:manifold_meshgl64_vert_properties _double)
(define-mesh-array meshgl64-triangle-vertices m64ptr c:manifold_meshgl64_tri_length c:manifold_meshgl64_tri_verts _uint64)
(define-mesh-array meshgl64-merge-from-vertices m64ptr c:manifold_meshgl64_merge_length c:manifold_meshgl64_merge_from_vert _uint64)
(define-mesh-array meshgl64-merge-to-vertices m64ptr c:manifold_meshgl64_merge_length c:manifold_meshgl64_merge_to_vert _uint64)
(define-mesh-array meshgl64-run-indices m64ptr c:manifold_meshgl64_run_index_length c:manifold_meshgl64_run_index _uint64)
(define-mesh-array meshgl64-run-original-ids m64ptr c:manifold_meshgl64_run_original_id_length c:manifold_meshgl64_run_original_id _uint32)
(define-mesh-array meshgl64-run-transforms m64ptr c:manifold_meshgl64_run_transform_length c:manifold_meshgl64_run_transform _double)
(define-mesh-array meshgl64-face-ids m64ptr c:manifold_meshgl64_face_id_length c:manifold_meshgl64_face_id _uint64)
(define-mesh-array meshgl64-halfedge-tangents m64ptr c:manifold_meshgl64_tangent_length c:manifold_meshgl64_halfedge_tangent _double)
(define (meshgl64-tolerance mesh) (c:manifold_meshgl64_tolerance (m64ptr 'meshgl64-tolerance mesh)))
(define-mesh-array meshgl64-run-flags m64ptr c:manifold_meshgl64_run_flags_length c:manifold_meshgl64_run_flags _uint8)
(define (meshgl64-num-runs mesh) (c:manifold_meshgl64_num_run (m64ptr 'meshgl64-num-runs mesh)))
(define (meshgl64-backside? mesh run) (bool (c:manifold_meshgl64_backside (m64ptr 'meshgl64-backside? mesh) run)))
(define (meshgl64-has-normals? mesh run) (bool (c:manifold_meshgl64_has_normals (m64ptr 'meshgl64-has-normals? mesh) run)))

;; Triangulation, OBJ I/O, and process-wide quality settings ----------------
(define (triangulate p [epsilon -1]) (make-owned 'triangulate c:manifold_alloc_triangulation c:manifold_delete_triangulation triangulation-handle c:manifold_triangulate (pptr 'triangulate p) (->double 'triangulate epsilon)))
(define (triangulation-num-triangles t) (c:manifold_triangulation_num_tri (triptr 'triangulation-num-triangles t)))
(define (triangulation-triangles t)
  (define ptr (triptr 'triangulation-triangles t))
  (define n (c:manifold_triangulation_num_tri ptr))
  (define mem (malloc (* n 3 (ctype-sizeof _int)) 'atomic))
  (c:manifold_triangulation_tri_verts mem ptr)
  (for/vector ([i (in-range n)]) (ivec3 (ptr-ref mem _int (* 3 i)) (ptr-ref mem _int (+ 1 (* 3 i))) (ptr-ref mem _int (+ 2 (* 3 i))))))
(define (nul-terminated-memory who text)
  (unless (string? text) (raise-argument-error who "string?" text))
  (define bytes (bytes-append (string->bytes/utf-8 text) #"\0"))
  (define mem (malloc (bytes-length bytes) 'atomic))
  (for ([b (in-bytes bytes)] [i (in-naturals)]) (ptr-set! mem _byte i b))
  mem)
(define (manifold-read-obj text) (construct-manifold 'manifold-read-obj c:manifold_read_obj (nul-terminated-memory 'manifold-read-obj text)))
(define (meshgl64-read-obj text) (construct-meshgl64 'meshgl64-read-obj c:manifold_meshgl64_read_obj (nul-terminated-memory 'meshgl64-read-obj text)))
(define (native-write-obj who native ptr)
  (define result #f)
  (native ptr (lambda (text ignored) (set! result (cast text _pointer _string/utf-8))) #f)
  (or result ""))
(define (manifold-write-obj m) (native-write-obj 'manifold-write-obj c:manifold_write_obj (mptr 'manifold-write-obj m)))
(define (meshgl64-write-obj mesh) (native-write-obj 'meshgl64-write-obj c:manifold_meshgl64_write_obj (m64ptr 'meshgl64-write-obj mesh)))
(define (set-relative-precision! value) (c:manifold_set_relative_precision (->double 'set-relative-precision! value)))
(define (relative-precision) (c:manifold_get_relative_precision))
(define (set-min-circular-angle! value) (c:manifold_set_min_circular_angle (->double 'set-min-circular-angle! value)))
(define (set-min-circular-edge-length! value) (c:manifold_set_min_circular_edge_length (->double 'set-min-circular-edge-length! value)))
(define (set-circular-segments! value) (c:manifold_set_circular_segments value))
(define (reset-circular-defaults!) (c:manifold_reset_to_circular_defaults))

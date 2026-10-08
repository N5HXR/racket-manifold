;; Included lexically by ../main.rkt. This file intentionally has no #lang.

(provide
 (struct-out ray-hit)
 cross-section? cross-section-close! cross-section-closed?
 polygon polygons square circle
 cross-section-copy cross-section-empty?
 cross-section-union cross-section-difference cross-section-intersection
 cross-section-hull cross-section-offset cross-section-simplify
 cross-section-translate cross-section-rotate cross-section-scale
 cross-section-mirror cross-section-transform cross-section-warp
 cross-section-area cross-section-num-vertices cross-section-num-contours
 cross-section-bounds cross-section->polygons
 extrude revolve solid-slice solid-project
 split split-by-plane warp smooth-by-normals
 level-set mesh->solid
 solid-ray-cast
 read-obj read-obj-file solid->obj-string write-obj)

(struct cross-section (handle))
(struct ray-hit (face-id distance position normal) #:transparent)

(define (cross-section-close! value)
  (unless (cross-section? value)
    (raise-argument-error 'cross-section-close! "cross-section?" value))
  (ll:native-handle-close! (cross-section-handle value)))
(define (cross-section-closed? value)
  (unless (cross-section? value)
    (raise-argument-error 'cross-section-closed? "cross-section?" value))
  (ll:native-handle-closed? (cross-section-handle value)))
(define (section-handle/checked who value)
  (unless (cross-section? value) (raise-argument-error who "cross-section?" value))
  (when (cross-section-closed? value)
    (raise-arguments-error who "cross-section has been closed" "cross-section" value))
  (cross-section-handle value))
(define (wrap-section handle) (cross-section handle))

(define (point2-like who value)
  (define items
    (cond [(and (list? value) (= (length value) 2)) value]
          [(and (vector? value) (= (vector-length value) 2)) (vector->list value)]
          [else (raise-argument-error who "two-element point list or vector" value)]))
  (for ([item items]) (finite-real who item))
  items)
(define (point2-sequence who values)
  (unless (sequence? values) (raise-argument-error who "sequence?" values))
  (for/list ([value values]) (point2-like->list who value)))
(define (point2-like->list who value) (point2-like who value))

(define fill-rules (hash 'nonzero #f 'even-odd #t))
(define (fill-rule-value who rule)
  (hash-ref fill-rules rule
            (lambda () (raise-argument-error who "(or/c 'nonzero 'even-odd)" rule))))

(define (polygon points #:fill-rule [fill-rule 'nonzero])
  (define native-polygon (ll:simple-polygon (point2-sequence 'polygon points)))
  (dynamic-wind void
    (lambda ()
      (wrap-section
       ((if (fill-rule-value 'polygon fill-rule)
            ll:cross-section-even-odd-simple-polygon
            ll:cross-section-of-simple-polygon)
        native-polygon)))
    (lambda () (ll:native-handle-close! native-polygon))))

(define (polygons contours #:fill-rule [fill-rule 'nonzero])
  (unless (sequence? contours) (raise-argument-error 'polygons "sequence?" contours))
  (define native-simples
    (for/list ([contour contours])
      (ll:simple-polygon (point2-sequence 'polygons contour))))
  (define native-polygons (ll:polygons native-simples))
  (dynamic-wind void
    (lambda ()
      (wrap-section
       ((if (fill-rule-value 'polygons fill-rule)
            ll:cross-section-even-odd-polygons
            ll:cross-section-of-polygons)
        native-polygons)))
    (lambda ()
      (ll:native-handle-close! native-polygons)
      (for-each ll:native-handle-close! native-simples))))

(define (square x [y x] #:center? [center? #f])
  (positive-real 'square x) (positive-real 'square y)
  (wrap-section (ll:cross-section-square x y center?)))
(define (circle radius #:segments [segments (current-circular-segments)])
  (positive-real 'circle radius) (segments-value 'circle segments)
  (wrap-section (ll:cross-section-circle radius segments)))
(define (cross-section-copy section)
  (wrap-section (ll:cross-section-copy (section-handle/checked 'cross-section-copy section))))
(define (cross-section-empty? section)
  (ll:cross-section-empty? (section-handle/checked 'cross-section-empty? section)))

(define (sections who values minimum)
  (unless (and (list? values) (>= (length values) minimum) (andmap cross-section? values))
    (raise-argument-error who (format "list of at least ~a cross-sections" minimum) values))
  (map (lambda (value) (section-handle/checked who value)) values))
(define (cross-section-union first . rest)
  (define handles (sections 'cross-section-union (cons first rest) 1))
  (wrap-section
   (if (null? rest) (ll:cross-section-copy (car handles))
       (ll:cross-section-batch-boolean handles 'add))))
(define (cross-section-intersection first . rest)
  (define handles (sections 'cross-section-intersection (cons first rest) 1))
  (wrap-section
   (if (null? rest) (ll:cross-section-copy (car handles))
       (ll:cross-section-batch-boolean handles 'intersect))))
(define (cross-section-difference base . cutters)
  (define handles (sections 'cross-section-difference (cons base cutters) 1))
  (cond [(null? cutters) (wrap-section (ll:cross-section-copy (car handles)))]
        [(null? (cdr cutters))
         (wrap-section (ll:cross-section-difference (car handles) (cadr handles)))]
        [else
         (define combined (apply cross-section-union cutters))
         (dynamic-wind void
           (lambda () (cross-section-difference base combined))
           (lambda () (cross-section-close! combined))) ]))
(define (cross-section-hull first . rest)
  (define handles (sections 'cross-section-hull (cons first rest) 1))
  (wrap-section
   (if (null? rest) (ll:cross-section-hull (car handles))
       (ll:cross-section-batch-hull handles))))

(define (cross-section-offset section delta
                              #:join [join 'round]
                              #:miter-limit [miter-limit 2]
                              #:segments [segments (current-circular-segments)])
  (finite-real 'cross-section-offset delta)
  (wrap-section
   (ll:cross-section-offset (section-handle/checked 'cross-section-offset section)
                            delta join miter-limit segments)))
(define (cross-section-simplify section [tolerance 0])
  (wrap-section
   (ll:cross-section-simplify
    (section-handle/checked 'cross-section-simplify section) tolerance)))
(define (cross-section-translate section offset [y #f])
  (define point (if y (list offset y) (point2-like 'cross-section-translate offset)))
  (wrap-section
   (ll:cross-section-translate
    (section-handle/checked 'cross-section-translate section)
    (car point) (cadr point))))
(define (cross-section-rotate section degrees)
  (wrap-section (ll:cross-section-rotate
                 (section-handle/checked 'cross-section-rotate section) degrees)))
(define (cross-section-scale section x [y x])
  (wrap-section (ll:cross-section-scale
                 (section-handle/checked 'cross-section-scale section) x y)))
(define (cross-section-mirror section axis)
  (define point (point2-like 'cross-section-mirror axis))
  (wrap-section (ll:cross-section-mirror
                 (section-handle/checked 'cross-section-mirror section)
                 (car point) (cadr point))))
(define (cross-section-transform section matrix)
  (unless (and (list? matrix) (= (length matrix) 2)
               (andmap (lambda (row) (and (list? row) (= (length row) 3))) matrix))
    (raise-argument-error 'cross-section-transform "two lists of three finite reals" matrix))
  (match-define (list (list r00 r01 tx) (list r10 r11 ty)) matrix)
  (wrap-section (ll:cross-section-transform
                 (section-handle/checked 'cross-section-transform section)
                 r00 r10 r01 r11 tx ty)))
(define (cross-section-warp section procedure)
  (wrap-section (ll:cross-section-warp
                 (section-handle/checked 'cross-section-warp section) procedure)))
(define (cross-section-area section)
  (ll:cross-section-area (section-handle/checked 'cross-section-area section)))
(define (cross-section-num-vertices section)
  (ll:cross-section-num-vertices (section-handle/checked 'cross-section-num-vertices section)))
(define (cross-section-num-contours section)
  (ll:cross-section-num-contours (section-handle/checked 'cross-section-num-contours section)))
(define (cross-section-bounds section)
  (define native (ll:cross-section-bounds (section-handle/checked 'cross-section-bounds section)))
  (dynamic-wind void
    (lambda ()
      (values (list (ll:vec2-x (ll:rect-min native)) (ll:vec2-y (ll:rect-min native)))
              (list (ll:vec2-x (ll:rect-max native)) (ll:vec2-y (ll:rect-max native)))))
    (lambda () (ll:native-handle-close! native))))
(define (cross-section->polygons section)
  (define native (ll:cross-section->polygons
                  (section-handle/checked 'cross-section->polygons section)))
  (dynamic-wind void
    (lambda ()
      (for/list ([i (in-range (ll:polygons-length native))])
        (for/list ([j (in-range (ll:polygons-simple-length native i))])
          (define p (ll:polygons-point native i j))
          (list (ll:vec2-x p) (ll:vec2-y p)))))
    (lambda () (ll:native-handle-close! native))))

(define (with-section-polygons who section procedure)
  (define native (ll:cross-section->polygons (section-handle/checked who section)))
  (dynamic-wind void (lambda () (procedure native))
                (lambda () (ll:native-handle-close! native))))
(define (extrude section height #:slices [slices 0] #:twist [twist 0]
                 #:scale [scale-value '(1 1)])
  (positive-real 'extrude height)
  (define scale-point (point2-like 'extrude scale-value))
  (with-section-polygons
   'extrude section
   (lambda (native)
     (checked-solid 'extrude
       (ll:manifold-extrude native height slices twist
                            (car scale-point) (cadr scale-point))))))
(define (revolve section #:segments [segments (current-circular-segments)]
                 #:degrees [degrees 360])
  (with-section-polygons
   'revolve section
   (lambda (native)
     (checked-solid 'revolve (ll:manifold-revolve native segments degrees)))))
(define (native-polygons->section who native)
  (dynamic-wind void
    (lambda () (wrap-section (ll:cross-section-of-polygons native)))
    (lambda () (ll:native-handle-close! native))))
(define (solid-slice value height)
  (native-polygons->section 'solid-slice
    (ll:manifold-slice (solid-handle/checked 'solid-slice value) height)))
(define (solid-project value)
  (native-polygons->section 'solid-project
    (ll:manifold-project (solid-handle/checked 'solid-project value))))

(define (split value cutter)
  (define-values (first second)
    (ll:manifold-split (solid-handle/checked 'split value)
                       (solid-handle/checked 'split cutter)))
  (values (checked-solid 'split first) (checked-solid 'split second)))
(define (split-by-plane value normal offset)
  (define p (point-like->point3 'split-by-plane normal))
  (define-values (first second)
    (ll:manifold-split-by-plane
     (solid-handle/checked 'split-by-plane value)
     (point3-x p) (point3-y p) (point3-z p) offset))
  (values (checked-solid 'split-by-plane first)
          (checked-solid 'split-by-plane second)))
(define (warp value procedure)
  (checked-solid 'warp
    (ll:manifold-warp (solid-handle/checked 'warp value) procedure)))
(define (smooth-by-normals value normal-index)
  (checked-solid 'smooth-by-normals
    (ll:manifold-smooth-by-normals
     (solid-handle/checked 'smooth-by-normals value) normal-index)))

(define (level-set procedure minimum maximum edge-length
                   #:level [level 0] #:tolerance [tolerance -1])
  (define lo (point-like->point3 'level-set minimum))
  (define hi (point-like->point3 'level-set maximum))
  (define bounds
    (ll:box (point3-x lo) (point3-y lo) (point3-z lo)
            (point3-x hi) (point3-y hi) (point3-z hi)))
  (dynamic-wind void
    (lambda ()
      (checked-solid 'level-set
        (ll:manifold-level-set-sequential procedure bounds edge-length level tolerance)))
    (lambda () (ll:native-handle-close! bounds))))

(define (mesh->solid value)
  (unless (mesh? value) (raise-argument-error 'mesh->solid "mesh?" value))
  (define native
    (ll:meshgl64
     (for/list ([p (in-vector (mesh-vertices value))])
       (list (point3-x p) (point3-y p) (point3-z p)))
     3
     (for/list ([face (in-vector (mesh-triangles value))])
       (list (triangle-a face) (triangle-b face) (triangle-c face)))))
  (dynamic-wind void
    (lambda () (checked-solid 'mesh->solid (ll:manifold-of-meshgl64 native)))
    (lambda () (ll:native-handle-close! native))))

(define (solid-ray-cast value origin end)
  (for/list ([hit (in-list
                   (ll:manifold-ray-cast
                    (solid-handle/checked 'solid-ray-cast value) origin end))])
    (ray-hit (ll:ray-hit-face-id hit) (ll:ray-hit-distance hit)
             (let ([p (ll:ray-hit-position hit)])
               (point3 (ll:vec3-x p) (ll:vec3-y p) (ll:vec3-z p)))
             (let ([p (ll:ray-hit-normal hit)])
               (point3 (ll:vec3-x p) (ll:vec3-y p) (ll:vec3-z p))))))

(define (read-obj source)
  (define text
    (cond [(input-port? source) (port->string source)]
          [(string? source) source]
          [else (raise-argument-error 'read-obj "(or/c input-port? string?)" source)]))
  (checked-solid 'read-obj (ll:manifold-read-obj text)))
(define (read-obj-file path)
  (unless (path-string? path) (raise-argument-error 'read-obj-file "path-string?" path))
  (call-with-input-file path read-obj))
(define (solid->obj-string value)
  (ll:manifold-write-obj (solid-handle/checked 'solid->obj-string value)))
(define (write-obj value destination)
  (define text (solid->obj-string value))
  (cond [(output-port? destination) (display text destination)]
        [(path-string? destination)
         (call-with-output-file destination (lambda (port) (display text port))
                                #:exists 'replace)]
        [else (raise-argument-error 'write-obj "(or/c path-string? output-port?)" destination)])
  (void))

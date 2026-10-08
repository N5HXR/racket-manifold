#lang racket/base

(require racket/list
         racket/include
         (prefix-in core: "main.rkt"))

(provide
 (struct-out unit)
 metre meter centimetre centimeter millimetre millimeter micrometre
 inch foot
 metres meters centimetres centimeters millimetres millimeters micrometres
 inches feet
 length? length->metres length-in
 current-length-unit
 with-units
 current-circular-segments
 with-circular-segments
 solid? solid-close! solid-closed? solid->unitless
 empty-solid tetrahedron cube cylinder sphere capsule between
 union difference intersection hull trim-by-plane
 minkowski-sum minkowski-difference translate rotate scale transform mirror
 refine refine-to-length refine-to-tolerance simplify
 solid-empty? solid-num-vertices solid-num-edges solid-num-triangles solid-genus
 solid-surface-area solid-volume solid-bounds
 solid-min-gap solid-winding-number
 write-stl solid->stl-bytes
 manifold-version manifold-library-path)

(define manifold-version core:manifold-version)
(define manifold-library-path core:manifold-library-path)
(define current-circular-segments core:current-circular-segments)

(define-syntax-rule (with-circular-segments count body ...)
  (parameterize ([current-circular-segments count]) body ...))

;; Scale is the exact number of metres represented by one unit.
(struct unit (name scale) #:transparent)
(struct physical-length (metres) #:transparent)
(struct physical-solid (core))

(define metre (unit 'metre 1))
(define meter metre)
(define centimetre (unit 'centimetre 1/100))
(define centimeter centimetre)
(define millimetre (unit 'millimetre 1/1000))
(define millimeter millimetre)
(define micrometre (unit 'micrometre 1/1000000))
(define inch (unit 'inch 127/5000))
(define foot (unit 'foot (* 12 (unit-scale inch))))

(define (make-length-constructor chosen-unit)
  (lambda (value)
    (unless (and (real? value) (rational? value))
      (raise-argument-error (unit-name chosen-unit) "finite-real?" value))
    (physical-length (* value (unit-scale chosen-unit)))))

(define metres (make-length-constructor metre))
(define meters metres)
(define centimetres (make-length-constructor centimetre))
(define centimeters centimetres)
(define millimetres (make-length-constructor millimetre))
(define millimeters millimetres)
(define micrometres (make-length-constructor micrometre))
(define inches (make-length-constructor inch))
(define feet (make-length-constructor foot))

(define (length->metres value)
  (unless (length? value) (raise-argument-error 'length->metres "length?" value))
  (physical-length-metres value))

(define (length-in value chosen-unit)
  (unless (length? value) (raise-argument-error 'length-in "length?" value))
  (unless (unit? chosen-unit) (raise-argument-error 'length-in "unit?" chosen-unit))
  (/ (physical-length-metres value) (unit-scale chosen-unit)))

(define length? physical-length?)

(define current-length-unit (make-parameter #f))

(define-syntax-rule (with-units chosen-unit body ...)
  (let ([selected chosen-unit])
    (unless (unit? selected)
      (raise-argument-error 'with-units "unit?" selected))
    (parameterize ([current-length-unit selected]) body ...)))

(define (active-unit who [explicit #f])
  (cond
    [explicit
     (unless (unit? explicit) (raise-argument-error who "unit?" explicit))
     explicit]
    [(current-length-unit) => values]
    [else
     (error who
            "no physical unit context; wrap the operation in (with-units UNIT ...)" )]))

(define (physical-value who value)
  (cond
    [(length? value) (physical-length-metres value)]
    [(and (real? value) (rational? value))
     (* value (unit-scale (active-unit who)))]
    [else (raise-argument-error who "(or/c finite-real? length?)" value)]))

(define (physical-point who value)
  (define items
    (cond
      [(and (list? value) (= (length value) 3)) value]
      [(and (vector? value) (= (vector-length value) 3)) (vector->list value)]
      [else (raise-argument-error who "three-element list or vector" value)]))
  (map (lambda (item) (physical-value who item)) items))

(define (solid? value) (physical-solid? value))
(define (solid->unitless value)
  (unless (solid? value) (raise-argument-error 'solid->unitless "solid?" value))
  (physical-solid-core value))
(define (wrap value) (physical-solid value))

(define (solid-close! value) (core:solid-close! (solid->unitless value)))
(define (solid-closed? value) (core:solid-closed? (solid->unitless value)))

(define (empty-solid) (active-unit 'empty-solid) (wrap (core:empty-solid)))
(define (tetrahedron) (active-unit 'tetrahedron) (wrap (core:tetrahedron)))

(define (cube x [y x] [z x] #:center? [center? #f])
  (wrap (core:cube (physical-value 'cube x)
                   (physical-value 'cube y)
                   (physical-value 'cube z)
                   #:center? center?)))

(define (cylinder height radius
                  #:top-radius [top-radius radius]
                  #:segments [segments (current-circular-segments)]
                  #:center? [center? #f])
  (wrap
   (core:cylinder (physical-value 'cylinder height)
                  (physical-value 'cylinder radius)
                  #:top-radius (physical-value 'cylinder top-radius)
                  #:segments segments #:center? center?)))

(define (sphere radius #:segments [segments (current-circular-segments)])
  (wrap (core:sphere (physical-value 'sphere radius) #:segments segments)))

(define (between a b radius #:segments [segments (current-circular-segments)])
  (wrap (core:between (physical-point 'between a)
                      (physical-point 'between b)
                      (physical-value 'between radius)
                      #:segments segments)))

(define (capsule a b radius #:segments [segments (current-circular-segments)])
  (wrap (core:capsule (physical-point 'capsule a)
                      (physical-point 'capsule b)
                      (physical-value 'capsule radius)
                      #:segments segments)))

(define (ensure-solids who values)
  (for/list ([value (in-list values)])
    (unless (solid? value) (raise-argument-error who "solid?" value))
    (physical-solid-core value)))

(define (union first . rest)
  (wrap (apply core:union (ensure-solids 'union (cons first rest)))))

(define (intersection first . rest)
  (wrap (apply core:intersection
               (ensure-solids 'intersection (cons first rest)))))

(define (difference base . cutters)
  (wrap (apply core:difference
               (ensure-solids 'difference (cons base cutters)))))

(define (hull first . rest)
  (wrap (apply core:hull (ensure-solids 'hull (cons first rest)))))

(define (trim-by-plane value normal offset)
  (wrap (core:trim-by-plane (solid->unitless value) normal
                            (physical-value 'trim-by-plane offset))))

(define (minkowski-sum a b)
  (wrap (core:minkowski-sum (solid->unitless a) (solid->unitless b))))

(define (minkowski-difference a b)
  (wrap (core:minkowski-difference
         (solid->unitless a) (solid->unitless b))))

(define (translate value offset [y #f] [z #f])
  (define converted
    (if (and y z)
        (map (lambda (item) (physical-value 'translate item)) (list offset y z))
        (physical-point 'translate offset)))
  (wrap (core:translate (solid->unitless value) converted)))

(define (rotate value x [y 0] [z 0])
  (wrap (core:rotate (solid->unitless value) x y z)))

(define (scale value x [y x] [z x])
  (wrap (core:scale (solid->unitless value) x y z)))

(define (transform value matrix)
  (unless (and (list? matrix) (= (length matrix) 3)
               (andmap (lambda (row) (and (list? row) (= (length row) 4))) matrix))
    (raise-argument-error 'transform "three lists of four values" matrix))
  (define converted
    (for/list ([row matrix])
      (list (list-ref row 0) (list-ref row 1) (list-ref row 2)
            (physical-value 'transform (list-ref row 3)))))
  (wrap (core:transform (solid->unitless value) converted)))

(define (mirror value normal)
  ;; Plane normals are directions, hence dimensionless.
  (wrap (core:mirror (solid->unitless value) normal)))

(define (refine value count)
  (wrap (core:refine (solid->unitless value) count)))

(define (refine-to-length value length)
  (wrap (core:refine-to-length
         (solid->unitless value) (physical-value 'refine-to-length length))))

(define (refine-to-tolerance value tolerance)
  (wrap (core:refine-to-tolerance
         (solid->unitless value)
         (physical-value 'refine-to-tolerance tolerance))))

(define (simplify value [tolerance 0])
  (wrap (core:simplify
         (solid->unitless value)
         (if (zero? tolerance) 0 (physical-value 'simplify tolerance)))))

(define (solid-empty? value) (core:solid-empty? (solid->unitless value)))
(define (solid-num-vertices value)
  (core:solid-num-vertices (solid->unitless value)))
(define (solid-num-edges value) (core:solid-num-edges (solid->unitless value)))
(define (solid-num-triangles value)
  (core:solid-num-triangles (solid->unitless value)))
(define (solid-genus value) (core:solid-genus (solid->unitless value)))

(define (solid-surface-area value)
  (define scale (unit-scale (active-unit 'solid-surface-area)))
  (/ (core:solid-surface-area (solid->unitless value)) (* scale scale)))

(define (solid-volume value)
  (define scale (unit-scale (active-unit 'solid-volume)))
  (/ (core:solid-volume (solid->unitless value)) (* scale scale scale)))

(define (solid-min-gap value other search-length)
  (define selected (active-unit 'solid-min-gap))
  (/ (core:solid-min-gap
      (solid->unitless value) (solid->unitless other)
      (physical-value 'solid-min-gap search-length))
     (unit-scale selected)))

(define (solid-winding-number value point)
  (core:solid-winding-number
   (solid->unitless value) (physical-point 'solid-winding-number point)))

(define (solid-bounds value)
  (define selected (active-unit 'solid-bounds))
  (define divisor (unit-scale selected))
  (define-values (minimum maximum) (core:solid-bounds (solid->unitless value)))
  (define (convert point)
    (list (/ (core:point3-x point) divisor)
          (/ (core:point3-y point) divisor)
          (/ (core:point3-z point) divisor)))
  (values (convert minimum) (convert maximum)))

(define (scaled-for-export who value chosen-unit)
  (define selected (active-unit who chosen-unit))
  (define factor (/ 1 (unit-scale selected)))
  (core:scale (solid->unitless value) factor))

(define (write-stl value destination
                   #:format [format 'binary]
                   #:name [name "manifold"]
                   #:unit [chosen-unit #f])
  (define scaled (scaled-for-export 'write-stl value chosen-unit))
  (dynamic-wind
    void
    (lambda () (core:write-stl scaled destination #:format format #:name name))
    (lambda () (core:solid-close! scaled))))

(define (solid->stl-bytes value
                          #:format [format 'binary]
                          #:name [name "manifold"]
                          #:unit [chosen-unit #f])
  (define scaled (scaled-for-export 'solid->stl-bytes value chosen-unit))
  (dynamic-wind
    void
    (lambda () (core:solid->stl-bytes scaled #:format format #:name name))
    (lambda () (core:solid-close! scaled))))

(include "private/units-extra.inc")

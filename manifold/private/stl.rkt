#lang racket/base

(require racket/format
         racket/match
         racket/port)

(provide write-mesh-stl mesh->stl-bytes)

;; This module is representation-agnostic: accessors are resolved dynamically
;; to avoid a module cycle with main.rkt.
(define (mesh-parts value)
  (match (with-handlers ([exn:fail?
                          (lambda (_)
                            (raise-argument-error
                             'write-mesh-stl "transparent mesh structure" value))])
           (struct->vector value))
    [(vector _ vertices triangles) (values vertices triangles)]
    [_ (raise-argument-error 'write-mesh-stl "mesh" value)]))

(define (point-coordinates point)
  (match (struct->vector point)
    [(vector _ x y z) (values x y z)]
    [_ (raise-argument-error 'write-mesh-stl "point3" point)]))

(define (triangle-indices triangle)
  (match (struct->vector triangle)
    [(vector _ a b c) (values a b c)]
    [_ (raise-argument-error 'write-mesh-stl "triangle" triangle)]))

(define (point-vector point)
  (define-values (x y z) (point-coordinates point))
  (vector x y z))

(define (v- a b)
  (for/vector #:length 3 ([x (in-vector a)] [y (in-vector b)]) (- x y)))

(define (cross a b)
  (vector (- (* (vector-ref a 1) (vector-ref b 2))
             (* (vector-ref a 2) (vector-ref b 1)))
          (- (* (vector-ref a 2) (vector-ref b 0))
             (* (vector-ref a 0) (vector-ref b 2)))
          (- (* (vector-ref a 0) (vector-ref b 1))
             (* (vector-ref a 1) (vector-ref b 0)))))

(define (normal a b c)
  (define n (cross (v- b a) (v- c a)))
  (define length
    (sqrt (for/sum ([x (in-vector n)]) (* x x))))
  (if (zero? length)
      #(0.0 0.0 0.0)
      (for/vector #:length 3 ([x (in-vector n)]) (/ x length))))

(define (validated-face who vertices face)
  (define-values (a b c) (triangle-indices face))
  (define count (vector-length vertices))
  (for ([index (in-list (list a b c))])
    (unless (and (exact-nonnegative-integer? index) (< index count))
      (raise-arguments-error who "triangle index is out of range"
                             "index" index "vertex-count" count)))
  (values (point-vector (vector-ref vertices a))
          (point-vector (vector-ref vertices b))
          (point-vector (vector-ref vertices c))))

(define (write-f32 value out)
  (unless (and (real? value) (rational? value))
    (raise-argument-error 'write-stl "finite-real?" value))
  (define encoded (real->floating-point-bytes (exact->inexact value) 4 #f))
  ;; Reject overflow to a single-precision infinity.
  (unless (rational? (floating-point-bytes->real encoded #f))
    (raise-arguments-error 'write-stl
                           "coordinate exceeds STL single-precision range"
                           "coordinate" value))
  (write-bytes encoded out))

(define (write-u16 value out)
  (write-bytes (integer->integer-bytes value 2 #f #f) out))

(define (write-u32 value out)
  (write-bytes (integer->integer-bytes value 4 #f #f) out))

(define (binary-header name)
  (define raw (string->bytes/utf-8 (format "Racket manifold: ~a" name)))
  (bytes-append (subbytes raw 0 (min 80 (bytes-length raw)))
                (make-bytes (max 0 (- 80 (bytes-length raw))) 0)))

(define (write-binary mesh out name)
  (define-values (vertices triangles) (mesh-parts mesh))
  (define count (vector-length triangles))
  (when (> count #xffffffff)
    (error 'write-stl "binary STL supports at most 2^32-1 triangles"))
  (write-bytes (binary-header name) out)
  (write-u32 count out)
  (for ([face (in-vector triangles)])
    (define-values (a b c) (validated-face 'write-stl vertices face))
    (for ([value (in-vector (normal a b c))]) (write-f32 value out))
    (for ([point (in-list (list a b c))])
      (for ([value (in-vector point)]) (write-f32 value out)))
    (write-u16 0 out)))

(define (ascii-number value)
  (~r (exact->inexact value) #:precision 17))

(define (write-ascii mesh out name)
  (define-values (vertices triangles) (mesh-parts mesh))
  (fprintf out "solid ~a\n" name)
  (for ([face (in-vector triangles)])
    (define-values (a b c) (validated-face 'write-stl vertices face))
    (define n (normal a b c))
    (fprintf out "  facet normal ~a ~a ~a\n"
             (ascii-number (vector-ref n 0))
             (ascii-number (vector-ref n 1))
             (ascii-number (vector-ref n 2)))
    (display "    outer loop\n" out)
    (for ([point (in-list (list a b c))])
      (fprintf out "      vertex ~a ~a ~a\n"
               (ascii-number (vector-ref point 0))
               (ascii-number (vector-ref point 1))
               (ascii-number (vector-ref point 2))))
    (display "    endloop\n  endfacet\n" out))
  (fprintf out "endsolid ~a\n" name))

(define (write-to-port mesh out format name)
  (case format
    [(binary) (write-binary mesh out name)]
    [(ascii) (write-ascii mesh out name)]
    [else (raise-argument-error 'write-mesh-stl "(or/c 'binary 'ascii)" format)]))

(define (write-mesh-stl mesh destination #:format [format 'binary] #:name [name "manifold"])
  (cond
    [(output-port? destination) (write-to-port mesh destination format name)]
    [(path-string? destination)
     (call-with-output-file destination
       #:exists 'truncate/replace
       #:mode 'binary
       (lambda (out) (write-to-port mesh out format name)))]
    [else (raise-argument-error 'write-mesh-stl
                                "(or/c output-port? path-string?)"
                                destination)])
  (void))

(define (mesh->stl-bytes mesh #:format [format 'binary] #:name [name "manifold"])
  (call-with-output-bytes
   (lambda (out) (write-to-port mesh out format name))))

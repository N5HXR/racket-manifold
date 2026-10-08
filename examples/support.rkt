#lang racket/base

(require racket/file
         racket/format
         racket/path
         "../manifold/units.rkt")

(provide example-output-directory
         output-path
         emit-stl
         emit-obj
         report-solid
         close-solids)

(define example-output-directory
  (make-parameter
   (path->complete-path
    (or (getenv "MANIFOLD_EXAMPLE_OUTPUT") "example-output"))))

(define (output-path filename)
  (make-directory* (example-output-directory))
  (build-path (example-output-directory) filename))

(define (report-solid name value)
  (define-values (minimum maximum) (solid-bounds value))
  (printf "~a: bounds ~a .. ~a; volume ~a mm^3; ~a triangles\n"
          name minimum maximum (real->decimal-string (solid-volume value) 3)
          (solid-num-triangles value)))

(define (emit-stl name value)
  (define destination (output-path (string-append name ".stl")))
  (with-units millimetre
    (report-solid name value)
    (write-stl value destination #:name name))
  (printf "  wrote ~a\n" destination)
  destination)

(define (emit-obj name text)
  (define destination (output-path (string-append name ".obj")))
  (call-with-output-file destination
    (lambda (port) (display text port))
    #:exists 'replace)
  (printf "~a: wrote ~a\n" name destination)
  destination)

(define (close-solids . values)
  (for ([value (in-list values)]) (solid-close! value)))

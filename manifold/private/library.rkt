#lang racket/base

(require ffi/unsafe
         racket/file
         racket/list
         racket/path
         racket/promise
         racket/string)

(provide force-manifold-lib
         make-lazy-manifold-ffi-obj
         manifold-library-path
         manifold-library-override
         manifold-library-available?)

(define manifold-library-override
  (make-parameter (getenv "RACKET_MANIFOLDC_LIB")))

(define (candidate-paths)
  (define override (manifold-library-override))
  (define defaults
    (list "libmanifoldc.so.3"
          "libmanifoldc.so"
          "manifoldc"
          "/usr/local/lib/libmanifoldc.so.3"
          "/usr/local/lib/libmanifoldc.so"
          "/usr/lib/libmanifoldc.so.3"
          "/usr/lib/libmanifoldc.so"
          "/opt/homebrew/lib/libmanifoldc.dylib"
          "/usr/local/lib/libmanifoldc.dylib"
          "libmanifoldc.dylib"
          "manifoldc.dll"
          "libmanifoldc.dll"))
  ;; The ONLY switch is intentionally diagnostic: it lets tests and package
  ;; builders prove that requiring the Racket modules does not need the native
  ;; library, even on a machine where Manifold happens to be installed.
  (remove-duplicates
   (filter values
           (if (and override (getenv "RACKET_MANIFOLDC_LIB_ONLY"))
               (list override)
               (cons override defaults)))))

;; #f means that no native operation has needed the library yet. The binding is
;; updated when the synchronized promise below first succeeds.
(define manifold-library-path #f)

(define manifold-library-promise
  (delay/sync
   (define attempted '())
   (or
    (for/or ([candidate (in-list (candidate-paths))])
      (set! attempted (cons candidate attempted))
      (with-handlers ([exn:fail? (lambda (_) #f)])
        (define lib (ffi-lib candidate))
        (set! manifold-library-path candidate)
        lib))
    (raise
     (exn:fail
      (string-append
       "manifold: unable to load libmanifoldc\n"
       "  attempted: " (string-join (reverse attempted) ", ") "\n"
       "  install Manifold with MANIFOLD_CBIND=ON, arrange for the system "
       "loader to find it, or set RACKET_MANIFOLDC_LIB")
      (current-continuation-marks))))))

(define (force-manifold-lib)
  (force manifold-library-promise))

(define (manifold-library-available?)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (force-manifold-lib)
    #t))

(define (make-lazy-manifold-ffi-obj name type [arity #f])
  (define binding
    (delay/sync
     (get-ffi-obj name (force-manifold-lib) type)))
  (define (invoke . arguments)
    (apply (force binding) arguments))
  (if arity
      (procedure-reduce-arity invoke arity)
      invoke))

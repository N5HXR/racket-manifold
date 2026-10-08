#lang racket/base

(require ffi/unsafe
         racket/file
         racket/list
         racket/path
         racket/string)

(provide manifold-lib
         manifold-library-path
         manifold-library-override)

(define manifold-library-override
  (make-parameter (getenv "RACKET_MANIFOLDC_LIB")))

(define (candidate-paths)
  (filter
   values
   (list (manifold-library-override)
         "libmanifoldc.so.3"
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
         "libmanifoldc.dll")))

(define attempted '())
(define loaded-path #f)

(define manifold-lib
  (or
   (for/or ([candidate (in-list (remove-duplicates (candidate-paths)))])
     (set! attempted (cons candidate attempted))
     (with-handlers ([exn:fail? (lambda (_) #f)])
       (define lib (ffi-lib candidate))
       (set! loaded-path candidate)
       lib))
   (raise
    (exn:fail
     (string-append
      "manifold: unable to load libmanifoldc\n"
      "  attempted: " (string-join (reverse attempted) ", ") "\n"
      "  install Manifold with MANIFOLD_CBIND=ON, arrange for the system "
      "loader to find it, or set RACKET_MANIFOLDC_LIB")
     (current-continuation-marks)))))

(define manifold-library-path loaded-path)


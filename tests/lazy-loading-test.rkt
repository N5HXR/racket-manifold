#lang racket/base

(require rackunit
         racket/port
         racket/system)

(define racket-executable
  (or (find-executable-path "racket")
      (error 'lazy-loading-test "cannot find the Racket executable")))

(define (without-native-library expression)
  (define environment
    (environment-variables-copy (current-environment-variables)))
  (environment-variables-set!
   environment #"RACKET_MANIFOLDC_LIB"
   #"/definitely/missing/libmanifoldc.so")
  (environment-variables-set!
   environment #"RACKET_MANIFOLDC_LIB_ONLY" #"1")
  (define output (open-output-string))
  (define errors (open-output-string))
  (define status
    (parameterize ([current-environment-variables environment]
                   [current-output-port output]
                   [current-error-port errors])
      (system*/exit-code racket-executable "-e" expression)))
  (values status (get-output-string output) (get-output-string errors)))

(test-case "all public modules load without libmanifoldc"
  (define-values (status output errors)
    (without-native-library
     (string-append
      "(require manifold manifold/units manifold/low-level manifold/unsafe) "
      "(display manifold-library-path)")))
  (check-equal? status 0 errors)
  (check-equal? output "#f"))

(test-case "the first native operation reports the missing dependency"
  (define-values (status output errors)
    (without-native-library "(require manifold) (cube 1)"))
  (check-not-equal? status 0)
  (check-equal? output "")
  (check-regexp-match #rx"unable to load libmanifoldc" errors)
  (check-regexp-match #rx"RACKET_MANIFOLDC_LIB" errors))

#lang racket/base

(require racket/runtime-path)

(provide api-manifest
         api-symbol-count
         api-bound-symbols
         api-managed-symbols
         api-unsafe-only-symbols
         api-pending-symbols)

(define-runtime-path manifest-path "private/api-manifest.rktd")

(define api-manifest
  (call-with-input-file manifest-path read))

(define api-symbol-count (length api-manifest))
(define api-bound-symbols
  (for/list ([entry (in-list api-manifest)]
             #:when (memq (cadr entry) '(managed unsafe-only)))
    (car entry)))
(define api-managed-symbols
  (for/list ([entry (in-list api-manifest)] #:when (eq? (cadr entry) 'managed))
    (car entry)))
(define api-unsafe-only-symbols
  (for/list ([entry (in-list api-manifest)]
             #:when (eq? (cadr entry) 'unsafe-only))
    (car entry)))
(define api-pending-symbols
  (for/list ([entry (in-list api-manifest)] #:when (eq? (cadr entry) 'pending))
    (car entry)))

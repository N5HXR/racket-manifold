#lang racket/base

;; Exact generated declarations for all functions in the target manifoldc.h.
;; These retain native pointers, placement storage, callbacks, enum integers,
;; and allocation/destruction responsibilities. Prefer manifold/low-level or
;; manifold for ordinary Racket code.
(require "private/generated-unsafe.rkt")
(provide (all-from-out "private/generated-unsafe.rkt"))

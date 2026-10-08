#lang scribble/manual

@(require (for-label racket/base racket/contract manifold/units))

@title[#:tag "units-reference"]{Physical-Unit Facade}

@defmodule[manifold/units]

This module mirrors the dimensional functional operations documented in
@secref["functional-reference"]. Bare geometric numbers are interpreted in the
active unit, converted to canonical metres internally, and converted back for
dimensional query results and file output.

@defstruct*[unit ([name symbol?] [scale rational?]) #:transparent]

@defthing[metre unit?]
@defthing[meter unit?]
@defthing[millimetre unit?]
@defthing[millimeter unit?]
@defthing[centimetre unit?]
@defthing[centimeter unit?]
@defthing[micrometre unit?]
@defthing[inch unit?]
@defthing[foot unit?]

American spellings and plural length constructors are aliases.

@defparam[current-length-unit selected (or/c unit? #f) #:value #f]{
The active interpretation and presentation unit. Physical constructors signal
an error when no unit is active.}

@defform[(with-units selected body ...)]{
Evaluates @racket[body] with @racket[current-length-unit] set to
@racket[selected]. Contexts nest and restore automatically.}

@defform[(with-circular-segments count body ...)]{
Uses @racket[count] as the default circular resolution within @racket[body].}

@defparam[current-circular-segments count
          (or/c 0 (integer-in 3 +inf.0))
          #:value 0]{The unit facade shares the same dynamically scoped
circular-segment parameter as the unitless API.}

@defproc[(metres [value real?]) length?]
@defproc[(millimetres [value real?]) length?]
@defproc[(centimetres [value real?]) length?]
@defproc[(micrometres [value real?]) length?]
@defproc[(inches [value real?]) length?]
@defproc[(feet [value real?]) length?]
@defproc[(length? [value any/c]) boolean?]
@defproc[(length->metres [value length?]) real?]
@defproc[(length-in [value length?] [selected unit?]) real?]

The unit facade exports the same names for primitives, CSG, planar operations,
extrusion, revolution, splitting, SDFs, warps, meshes, rays, STL, and OBJ.
Lengths may be bare active-unit numbers or explicitly tagged values. Angles,
scale factors, counts, normals, and indices remain dimensionless.

@defproc[(solid? [value any/c]) boolean?]
@defproc[(solid-close! [value solid?]) void?]
@defproc[(cross-section? [value any/c]) boolean?]
@defproc[(cross-section-close! [value cross-section?]) void?]
@defproc[(square [x (or/c real? length?)] [y (or/c real? length?) x]
                 [#:center? center? boolean? #f]) cross-section?]
@defproc[(circle [radius (or/c real? length?)]
                 [#:segments segments exact-nonnegative-integer?
                  (current-circular-segments)]) cross-section?]
@defproc[(cross-section-difference [base cross-section?]
                                   [cutters cross-section?] ...) cross-section?]
@defproc[(extrude [section cross-section?] [height (or/c real? length?)]
                  [#:slices slices exact-nonnegative-integer? 0]
                  [#:twist twist real? 0]
                  [#:scale scale-value (or/c list? vector?) '(1 1)]) solid?]

@racketblock[
(with-units millimetre
  (with-circular-segments 48
    (define profile
      (cross-section-difference
       (square 40 20 #:center? #t)
       (circle 5)))
    (define part (extrude profile 3))
    (write-stl part "part-mm.stl")
    (cross-section-close! profile)
    (solid-close! part)))]

@defproc[(solid->unitless [value solid?]) any/c]{Returns the underlying
unitless Layer 2 solid as an advanced escape hatch. It must not be combined
with arbitrary unitless geometry unless coordinate scaling is intentional.}

@defproc[(write-stl [value solid?] [destination (or/c path-string? output-port?)]
                    [#:format format (or/c 'binary 'ascii) 'binary]
                    [#:name name string? "manifold"]
                    [#:unit selected (or/c unit? #f) #f]) void?]

The @racket[#:unit] value overrides the active unit for STL coordinate output.

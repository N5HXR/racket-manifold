#lang scribble/manual

@(require (for-label (except-in racket/base box)
                     racket/contract
                     manifold/low-level manifold/coverage))

@title[#:tag "low-level-reference"]{Managed Native Layer}

@defmodule[manifold/low-level]

The managed native layer covers all 292 functions in the targeted
@tt{manifoldc.h}. It preserves native object families and operation granularity
while removing caller-provided placement memory, pairing every owned result
with its native delete function, copying native output arrays, and adapting
callbacks to Racket procedures.

Names use hyphens and Racket predicate or mutation suffixes. Representative
families include:

@itemlist[
 @item{@tt{manifold-*}: construction, Boolean operations, transformations,
       topology, properties, measurements, level sets, rays, and OBJ I/O.}
 @item{@tt{cross-section-*}: planar construction, CSG, hulls, offsets,
       transforms, decomposition, and polygon conversion.}
 @item{@tt{meshgl-*} and @tt{meshgl64-*}: float or double mesh construction,
       copying, merging, metadata, run flags, transforms, and arrays.}
 @item{@tt{box-*} and @tt{rect-*}: native bounds and containment operations.}
 @item{@tt{execution-context-*}: progress, cancellation, level sets, and mesh
       realization.}]

@defproc[(native-handle? [value any/c]) boolean?]
@defproc[(native-handle-closed? [value native-handle?]) boolean?]
@defproc[(native-handle-close! [value native-handle?]) void?]

All native-handle subtypes share the same idempotent explicit-close and
finalizer behavior. Vector member access returns owned copies rather than
borrowed pointers.

@defproc[(manifold-version) (list/c exact-integer? exact-integer? exact-integer?)]

@tt{manifold-library-path} reports the candidate name or path used to load the
native library.

@section{Callbacks and Global Settings}

@tt{manifold-level-set} and @tt{manifold-level-set-sequential} both use
the sequential implementation for Racket callbacks. The explicitly named
execution-context parallel operation remains available for advanced users.

@tt{set-circular-segments!}, @tt{set-min-circular-angle!},
@tt{set-min-circular-edge-length!}, @tt{set-relative-precision!}, and
@tt{reset-circular-defaults!} map to Manifold's process-wide settings.
Prefer Layer 2's parameterized @racket[with-circular-segments] for ordinary
modeling.

@section{Coverage Accounting}

@defmodule[manifold/coverage]
@defthing[api-symbol-count exact-nonnegative-integer?]
@defthing[api-managed-symbols (listof symbol?)]
@defthing[api-unsafe-only-symbols (listof symbol?)]
@defthing[api-pending-symbols (listof symbol?)]

For the targeted header these values report 292 total, 292 managed, zero
unsafe-only, and zero pending symbols. Allocator, destructor, and native size
functions count as managed because the ownership layer internalizes them.

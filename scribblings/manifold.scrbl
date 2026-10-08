#lang scribble/manual

@(require scribble/core
          scribble/html-properties
          (for-label racket/base
                     racket/contract
                     manifold
                     manifold/coverage))

@title[#:tag "top"]{Manifold: Solid Modeling for Racket}
@author{Josh Stone}

This package wraps the
@hyperlink["https://github.com/elalish/manifold"]{Manifold} solid-modeling
library. It provides a complete binding to Manifold's C API and an idiomatic,
functional Racket interface for constructing watertight solids, planar cross
sections, triangle meshes, and STL or OBJ files.

The native Manifold library is an external dependency. This package targets
Manifold @tt{v3.5.1-82-g7b35cb6f}; install @tt{libmanifoldc} where the dynamic
linker can find it, or set @envvar{RACKET_MANIFOLDC_LIB} to the shared-library
path.

Loading any Racket module in this package does not immediately load the native
library. The first native operation locates @tt{libmanifoldc} and resolves its
required C binding. This permits package installation and documentation builds
on systems where Manifold is not installed; actual modeling operations still
report a direct, actionable error until the native dependency is available.

@local-table-of-contents[]

@section[#:tag "layers"]{Choosing an Interface}

@itemlist[
 @item{@racketmodname[manifold] is the unitless functional modeling API.}
 @item{@racketmodname[manifold/units] adds physical-unit contexts and prevents
       accidental mixing of physical and unitless solids.}
 @item{@racketmodname[manifold/low-level] preserves native Manifold concepts
       while managing ownership, arrays, and callbacks.}
 @item{@racketmodname[manifold/unsafe] exposes exact C names and pointer-level
       calling conventions for ABI work.}]

Layer 2 depends only on the managed low-level layer. The exact unsafe module is
never used by the functional implementation.

@section[#:tag "quick-start"]{Quick Start}

@racketblock[
(require manifold/units)

(define handle
  (with-units millimetre
    (with-circular-segments 40
      (define outside (square 60 24 #:center? #t))
      (define opening (circle 7))
      (define profile (cross-section-difference outside opening))
      (define result (extrude profile 5))
      (cross-section-close! outside)
      (cross-section-close! opening)
      (cross-section-close! profile)
      result)))

(with-units millimetre
  (write-stl handle "handle.stl"))

(solid-close! handle)]

The repository's @filepath{examples} directory contains a progression from a
cube to planar extrusion, callback-generated geometry, mesh round-tripping,
and a printable tugboat.

@section[#:tag "ownership"]{Ownership and Lifetimes}

Solids and cross sections behave functionally: operations return new values and
do not consume their arguments. Native storage is protected by finalizers.
Long-running programs and large model generators should additionally call
@racket[solid-close!] or @racket[cross-section-close!] when a value is no
longer required. Closing is idempotent; attempting to use a closed value raises
a Racket exception instead of passing a dangling pointer to C.

@section[#:tag "quality"]{Tessellation and Quality}

@racket[with-circular-segments] is the dynamically scoped equivalent of
OpenSCAD's @tt{$fn}. Individual @racket[#:segments] arguments override it.
The setting is implemented as a Racket parameter, so nested uses restore
automatically and do not mutate Manifold's process-wide quality globals.

Manifold also offers adaptive circular-angle and edge-length controls through
@racketmodname[manifold/low-level]. Relative precision is a separate numerical
robustness setting; refinement, simplification, and level-set sampling are
operation-specific controls.

@section[#:tag "callbacks"]{Callbacks}

Level-set and warp procedures use ordinary Racket callbacks. The functional
API always selects Manifold's sequential level-set implementation so callbacks
re-enter Racket on the calling thread. Parallel callback entry points remain in
the low-level and unsafe modules for deliberately validated foreign-runtime
uses.

@section[#:tag "files"]{STL, OBJ, and Physical Units}

STL and OBJ coordinates do not reliably carry physical units. The unit-aware
facade therefore scales exported coordinates into the active unit and treats
imported OBJ coordinates as values in the active unit. Binary STL is the
default; ASCII STL is available for diagnostics.

Generated STL has been exercised through Bambu Studio and the installed
OpenEMS/CSXCAD @tt{ImportSTL} reader. Material properties, priorities, ports,
and FDTD grid construction remain downstream responsibilities.

@include-section["reference.scrbl"]
@include-section["units.scrbl"]
@include-section["low-level.scrbl"]
@include-section["unsafe.scrbl"]

@section[#:tag "license"]{License and Upstream Attribution}

The Racket wrapper is distributed under the MIT License. Manifold is an
external Apache-2.0 dependency and is not bundled with this package.

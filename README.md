# manifold

Racket bindings for the [Manifold](https://github.com/elalish/manifold)
solid-modeling library.

This package currently targets Manifold checkout
`7b35cb6f3ebc3900e0858e08c1caa27fe716345a` (`v3.5.1-82-g7b35cb6f`).
Manifold is an external system dependency and must be installed separately
with its C bindings (`libmanifoldc`). Manifold is licensed under Apache-2.0;
this Racket wrapper is licensed under MIT.

The complete 292-symbol official C API is available with exact native names
from `manifold/unsafe`; those declarations are generated from `manifoldc.h`.
Every call is also covered by `manifold/low-level`: owned native values have
idempotent explicit close operations and finalizers, native output arrays are
copied into Racket vectors, callbacks receive and return Racket values, and
allocator/destructor calls are internalized by the corresponding managed
operation. The convenient `manifold` layer adds capsules and binary/ASCII STL
output.

The word “unsafe” now describes only the intentionally exact C interface, not
a gap in managed coverage. Normal applications should start with `manifold` or
`manifold/low-level`; `manifold/unsafe` remains available for ABI experiments
and future C API additions. See [`MANAGED-API.md`](MANAGED-API.md) for ownership
rules and the managed family overview, and [`LAYER2-API.md`](LAYER2-API.md) for
the functional modeling surface.

For a linked development install:

```sh
raco pkg install --auto --link /path/to/manifold
raco test -p manifold
```

Install the released source directly from GitHub with:

```sh
raco pkg install https://github.com/N5HXR/racket-manifold.git
```

After installation, open the searchable Scribble manual with:

```sh
raco docs manifold
```

## Quick start from a file

Save the following as `capsule.rkt` (the `#lang` line must be the first line
of a source file):

```racket
#lang racket
(require manifold)

(define bar (capsule '(0 0 0) '(0 0 10) 1 #:segments 32))
(write-stl bar "bar.stl")
(solid-close! bar)
```

Then run the file from your shell:

```sh
racket capsule.rkt
```

This writes `bar.stl` in the current directory.

## Quick start from the REPL

If you start the interactive REPL by running `racket` with no filename, omit
the `#lang` line. Also, module paths are not quoted: use
`(require manifold)`, not `(require 'manifold)`.

```racket
> (require manifold)
> (define bar (capsule '(0 0 0) '(0 0 10) 1 #:segments 32))
> (write-stl bar "bar.stl")
> (solid-close! bar)
```

## Units

For physical modeling, use `manifold/units`. Bare geometric numbers are
interpreted in the active unit context and normalized to metres internally:

```racket
#lang racket
(require manifold/units)

(define bar
  (with-units millimetre
    (capsule '(0 0 0) '(0 0 10) 1 #:segments 32)))

(with-units millimetre
  (write-stl bar "bar-mm.stl"))
```

Use `with-circular-segments` as the dynamically scoped equivalent of
OpenSCAD's `$fn`. A constructor's explicit `#:segments` argument overrides the
surrounding setting:

```racket
(with-units millimetre
  (with-circular-segments 48
    (union (sphere 10)
           (cylinder 30 4 #:segments 24))))
```

Manifold also has adaptive circular-angle and circular-edge-length settings at
the managed low level, plus a separate relative-precision setting. The latter
controls numerical robustness rather than visual tessellation. Refinement,
simplification, and level-set sampling are operation-specific quality controls,
not circular defaults.

The [`examples`](examples/README.md) directory contains an eight-stage modeling
ladder, beginning with a cube and ending with a printable pocket tug. Run all
examples with `racket examples/run-all.rkt --output example-output`.

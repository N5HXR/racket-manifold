# Example ladder

These examples progress from one primitive to a small printable assembly. Run
an individual example directly from this directory without installing the
Racket package:

```sh
racket 08-pocket-tug.rkt
```

The examples use relative imports specifically to support source-tree use.
Normal dependent programs should use collection imports such as
`(require manifold/units)` after installing or linking the package.

Run the complete suite with:

```sh
racket examples/run-all.rkt --output example-output
```

The `MANIFOLD_EXAMPLE_OUTPUT` environment variable is an alternative way to
choose the artifact directory. The default is `example-output` beneath the
current directory.

| Example | Main ideas | Artifact |
| --- | --- | --- |
| `01-cube.rkt` | units, primitive, measurements, STL | STL |
| `02-primitives-and-transforms.rkt` | sphere, cylinder, cone, translate, rotate, scale, union | STL |
| `03-boolean-bracket.rkt` | union, difference, intersection, multiple cutters | STL |
| `04-hull-and-minkowski.rkt` | convex hull, Minkowski sum, rounded forms | STL |
| `05-cross-section-extrusion.rkt` | Layer 2 planar CSG, offset, unit-aware extrusion | OBJ |
| `06-sdf-and-warp.rkt` | unit-aware SDF callback, sequential level set, warp callback | OBJ |
| `07-mesh-round-trip.rkt` | Layer 2 indexed mesh input, refinement, ray casting, extraction | OBJ |
| `08-pocket-tug.rkt` | scoped circular resolution, accumulated solid-modeling workflow, printable output | STL |

The examples deliberately print descriptive measurements instead of asserting
exact tessellation details. The package tests own regression assertions; this
suite is intended to be readable, modifiable, and visually inspectable in a
slicer or mesh viewer.

The final tugboat is not intended as a slicer torture test. It is a compact
“shippy” model that exercises ellipsoidal transforms, hulls, clipping,
multi-part unions, capsule geometry, and subtractive detail in one watertight
solid.

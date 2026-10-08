# Build status

This checkout is the complete managed-Layer-1 milestone of the Racket
Manifold wrapper described in the accompanying specification.

## Implemented

- Exact unsafe FFI bindings for all 292 functions declared by the targeted
  `manifoldc.h` checkout.
- A generated API-coverage manifest which distinguishes managed and unsafe-only
  bindings.
- Managed coverage for all 292 C calls, including native ownership, polygons,
  cross sections, meshes and metadata, execution contexts, callbacks, boxes,
  rectangles, triangulation, OBJ I/O, and process-wide quality controls.
- A functional convenience layer with dynamically scoped units, capsules, CSG,
  transformations, planar CSG, extrusion and revolution, SDFs and warps,
  mesh round-tripping, OBJ, and binary or ASCII STL output.
- Twenty-eight Racket tests covering lazy native loading, symbol resolution,
  ownership, geometry, units, callbacks, every managed API family, capsules,
  and STL serialization.
- Eight executable examples progressing from a unit-aware cube through CSG,
  planar extrusion, SDF callbacks, mesh round-tripping, and a printable tugboat.
- An installed, searchable Scribble manual covering the functional API, units,
  ownership, managed Layer 1, callbacks, files, and exact unsafe boundary.

## Independently exercised

- Racket 8.2 package installation and test execution.
- Package installation, module loading, Scribble generation, and graceful test
  skipping with `libmanifoldc` deliberately unavailable.
- Loading all generated native symbols from the locally installed Manifold C
  library.
- Importing a generated binary STL through the installed OpenEMS/CSXCAD STL
  reader and preprocessing it with `openEMS --no-simulation`.
- Loading the same STL in Bambu Studio, which reported the intended
  2 x 2 x 12 mm bounds and 35.0826 mm^3 volume.

## Deliberately deferred

- Racket generics and custom protocol extension.
- A direct OpenEMS geometry adapter beyond the supplied STL import example.
- MEEP-specific integration.

# Changelog

## 0.1.1

- Defer loading `libmanifoldc` and resolving C symbols until the first native
  operation, allowing package installation and documentation builds without
  the external library.
- Preserve exact unsafe-procedure arities across lazy binding resolution.
- Skip native integration tests cleanly when Manifold is unavailable and add
  subprocess coverage for missing-library imports and first-use errors.
- Clarify file, REPL, and user-scoped installation instructions.

## 0.1.0

Initial public alpha release.

- Exact FFI declarations for all 292 functions in the targeted Manifold C API.
- Managed native ownership and complete managed Layer 1 coverage.
- Functional unitless and physical-unit modeling APIs.
- Primitives, variadic CSG, transformations, capsules, planar modeling,
  extrusion, revolution, splitting, slicing, projection, SDFs, warps, rays,
  mesh round-tripping, and STL/OBJ I/O.
- Dynamically scoped circular tessellation control.
- Eight progressive examples and twenty-six behavioral tests.
- Installed Scribble reference manual.

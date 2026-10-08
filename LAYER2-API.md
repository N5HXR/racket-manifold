# Functional Layer 2

`manifold` is the unitless functional modeling API. `manifold/units` mirrors
its dimensional operations and normalizes physical geometry to metres. Both
modules are implemented exclusively through managed `manifold/low-level`.

## Solid modeling

The API includes primitives, capsules and point-to-point cylinders, variadic
CSG and hulls, affine transformations, splitting and trimming, refinement,
SDF level sets, coordinate warps, measurements, winding queries, and ray casts.
Operations return new values and never consume their inputs.

## Planar modeling

`polygon`, `polygons`, `square`, and `circle` construct managed cross sections.
Planar union, difference, intersection, hull, offset, simplification,
transformations, bounds, area, and contour conversion use ordinary Racket
lists and vectors at the public boundary. `extrude` and `revolve` convert a
cross section into a solid; `solid-slice` and `solid-project` travel in the
opposite direction.

## Tessellation

`with-circular-segments` is a dynamically scoped, thread-local equivalent of
OpenSCAD's `$fn`. An explicit `#:segments` keyword overrides it for an
individual circle, sphere, cylinder, capsule, offset, or revolution.

## Meshes and files

`solid->mesh` and `mesh->solid` use transparent Racket point, triangle, and
mesh structures with double-precision native conversion. Binary and ASCII STL
support paths, ports, and bytes. OBJ content uses `read-obj`,
`solid->obj-string`, and `write-obj`; `read-obj-file` is the explicit path
reader.

STL and OBJ contain coordinates but no reliable physical unit declaration.
The unit facade scales exported coordinates into the active unit and interprets
imported coordinates in the active unit.

## Lifetimes

Solids and cross sections have finalizers and may also be released
deterministically with `solid-close!` and `cross-section-close!`. Explicit
close is useful in generators or large models; examples generally close named
intermediate values after the final result has been constructed.

`racket/generic` protocols remain deliberately deferred until this functional
vocabulary has received real downstream use. They will delegate to these
functions rather than form a second implementation.

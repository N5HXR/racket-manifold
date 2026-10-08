# Managed Layer 1

`manifold/low-level` covers the complete C API while removing caller-managed
native storage. Its naming is Racket-oriented: C underscores become hyphens,
predicates end in `?`, mutations end in `!`, and copied native collections are
returned as lists or vectors.

## Ownership

Every opaque native result is represented by a subtype of `native-handle`.
Handles have an idempotent `native-handle-close!` operation and a finalizer.
Closing a handle early is optional but useful for large meshes; using a closed
handle raises a Racket exception instead of passing a dangling pointer to C.

Allocator, size, destructor, and delete calls from the C API are managed
internally. Calls returning native arrays copy their contents into Racket
vectors before the temporary storage can expire. Native vector containers are
available as managed handles where exact vector behavior matters, while batch
operations also accept ordinary Racket lists.

## Families

- Manifold construction, CSG, splitting, slicing, projection, hulls,
  composition, decomposition, transformations, refinement, and queries.
- Simple polygons, polygon sets, cross sections, offsets, planar CSG, and
  triangulation.
- Float and double MeshGL construction, metadata, extraction, conversion, and
  OBJ import/export.
- Rectangles, bounding boxes, ray casts, execution contexts, and process-wide
  quality settings.
- SDF, warp, and property callbacks translated to ordinary Racket procedures.

## Callbacks

`manifold-level-set` and `manifold-level-set-sequential` both select Manifold's
sequential implementation because callbacks enter the Racket runtime. The
execution-context parallel entry point is retained as
`execution-context-level-set`; use
`execution-context-level-set-sequential` unless the host runtime's foreign
thread callback behavior has been deliberately validated.

The exact native declarations—including allocation and raw-pointer operations—
remain available from `manifold/unsafe` for ABI debugging and unusual use
cases.

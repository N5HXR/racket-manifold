#lang scribble/manual

@(require (for-label racket/base racket/contract manifold))

@title[#:tag "functional-reference"]{Unitless Functional Reference}

@defmodule[manifold]

All coordinates in this module are unitless finite real values.

@section{Values and Resource Management}

@defstruct*[point3 ([x real?] [y real?] [z real?]) #:transparent]
@defstruct*[triangle ([a exact-nonnegative-integer?]
                      [b exact-nonnegative-integer?]
                      [c exact-nonnegative-integer?]) #:transparent]
@defstruct*[mesh ([vertices vector?] [triangles vector?]) #:transparent]
@defstruct*[ray-hit ([face-id exact-nonnegative-integer?]
                     [distance real?] [position point3?] [normal point3?])
                    #:transparent]

@defproc[(solid? [value any/c]) boolean?]
@defproc[(solid-close! [value solid?]) void?]
@defproc[(solid-closed? [value solid?]) boolean?]
@defproc[(cross-section? [value any/c]) boolean?]
@defproc[(cross-section-close! [value cross-section?]) void?]
@defproc[(cross-section-closed? [value cross-section?]) boolean?]

@section{Circular Resolution}

@defparam[current-circular-segments count
          (or/c 0 (integer-in 3 +inf.0))
          #:value 0]{The default segment count used by circular constructors.
Zero delegates to Manifold's adaptive default.}

@defform[(with-circular-segments count body ...)]{
Evaluates @racket[body] with @racket[current-circular-segments] set to
@racket[count]. Explicit constructor keywords take precedence.}

@section{Solid Constructors}

@defproc[(empty-solid) solid?]
@defproc[(tetrahedron) solid?]
@defproc[(cube [x real?] [y real? x] [z real? x]
               [#:center? center? boolean? #f]) solid?]
@defproc[(sphere [radius real?]
                 [#:segments segments exact-nonnegative-integer?
                  (current-circular-segments)]) solid?]
@defproc[(cylinder [height real?] [radius real?]
                   [#:top-radius top-radius real? radius]
                   [#:segments segments exact-nonnegative-integer?
                    (current-circular-segments)]
                   [#:center? center? boolean? #f]) solid?]
@defproc[(between [start (or/c point3? list? vector?)]
                  [end (or/c point3? list? vector?)] [radius real?]
                  [#:segments segments exact-nonnegative-integer?
                   (current-circular-segments)]) solid?]
@defproc[(capsule [start (or/c point3? list? vector?)]
                  [end (or/c point3? list? vector?)] [radius real?]
                  [#:segments segments exact-nonnegative-integer?
                   (current-circular-segments)]) solid?]

@section{Planar Constructors and Operations}

@defproc[(polygon [points sequence?]
                  [#:fill-rule fill-rule (or/c 'nonzero 'even-odd) 'nonzero])
         cross-section?]
@defproc[(polygons [contours sequence?]
                   [#:fill-rule fill-rule (or/c 'nonzero 'even-odd) 'nonzero])
         cross-section?]
@defproc[(square [x real?] [y real? x] [#:center? center? boolean? #f])
         cross-section?]
@defproc[(circle [radius real?]
                 [#:segments segments exact-nonnegative-integer?
                  (current-circular-segments)]) cross-section?]
@defproc[(cross-section-copy [section cross-section?]) cross-section?]
@defproc[(cross-section-empty? [section cross-section?]) boolean?]

@defproc[(cross-section-union [first cross-section?]
                              [rest cross-section?] ...) cross-section?]
@defproc[(cross-section-difference [base cross-section?]
                                   [cutters cross-section?] ...) cross-section?]
@defproc[(cross-section-intersection [first cross-section?]
                                     [rest cross-section?] ...) cross-section?]
@defproc[(cross-section-hull [first cross-section?]
                             [rest cross-section?] ...) cross-section?]
@defproc[(cross-section-offset [section cross-section?] [delta real?]
                               [#:join join (or/c 'square 'round 'miter 'bevel) 'round]
                               [#:miter-limit miter-limit real? 2]
                               [#:segments segments exact-nonnegative-integer?
                                (current-circular-segments)]) cross-section?]
@defproc[(cross-section-simplify [section cross-section?]
                                 [tolerance real? 0]) cross-section?]

@defproc[(cross-section-translate [section cross-section?]
                                  [offset (or/c list? vector?)] [y (or/c real? #f) #f])
         cross-section?]
@defproc[(cross-section-rotate [section cross-section?] [degrees real?]) cross-section?]
@defproc[(cross-section-scale [section cross-section?] [x real?] [y real? x]) cross-section?]
@defproc[(cross-section-mirror [section cross-section?] [axis (or/c list? vector?)]) cross-section?]
@defproc[(cross-section-transform [section cross-section?] [matrix list?]) cross-section?]
@defproc[(cross-section-warp [section cross-section?] [procedure procedure?]) cross-section?]

@defproc[(cross-section-area [section cross-section?]) real?]
@defproc[(cross-section-num-vertices [section cross-section?]) exact-nonnegative-integer?]
@defproc[(cross-section-num-contours [section cross-section?]) exact-nonnegative-integer?]
@defproc[(cross-section-bounds [section cross-section?])
         (values list? list?)]
@defproc[(cross-section->polygons [section cross-section?]) list?]

@section{CSG, Placement, and Topology}

@defproc[(union [first solid?] [rest solid?] ...) solid?]
@defproc[(difference [base solid?] [cutters solid?] ...) solid?]
@defproc[(intersection [first solid?] [rest solid?] ...) solid?]
@defproc[(hull [first solid?] [rest solid?] ...) solid?]
@defproc[(minkowski-sum [a solid?] [b solid?]) solid?]
@defproc[(minkowski-difference [a solid?] [b solid?]) solid?]
@defproc[(translate [value solid?] [offset (or/c point3? list? vector?)]
                    [y (or/c real? #f) #f] [z (or/c real? #f) #f]) solid?]
@defproc[(rotate [value solid?] [x real?] [y real? 0] [z real? 0]) solid?]
@defproc[(scale [value solid?] [x real?] [y real? x] [z real? x]) solid?]
@defproc[(transform [value solid?] [matrix list?]) solid?]
@defproc[(mirror [value solid?] [normal (or/c point3? list? vector?)]) solid?]
@defproc[(trim-by-plane [value solid?] [normal (or/c point3? list? vector?)]
                        [offset real?]) solid?]
@defproc[(split [value solid?] [cutter solid?]) (values solid? solid?)]
@defproc[(split-by-plane [value solid?] [normal (or/c point3? list? vector?)]
                         [offset real?]) (values solid? solid?)]

@section{Generation and Mesh Processing}

@defproc[(extrude [section cross-section?] [height real?]
                  [#:slices slices exact-nonnegative-integer? 0]
                  [#:twist twist real? 0]
                  [#:scale scale-value (or/c list? vector?) '(1 1)]) solid?]
@defproc[(revolve [section cross-section?]
                  [#:segments segments exact-nonnegative-integer?
                   (current-circular-segments)]
                  [#:degrees degrees real? 360]) solid?]
@defproc[(solid-slice [value solid?] [height real?]) cross-section?]
@defproc[(solid-project [value solid?]) cross-section?]
@defproc[(level-set [procedure procedure?] [minimum (or/c list? vector?)]
                    [maximum (or/c list? vector?)] [edge-length real?]
                    [#:level level real? 0]
                    [#:tolerance tolerance real? -1]) solid?]
@defproc[(warp [value solid?] [procedure procedure?]) solid?]
@defproc[(smooth-by-normals [value solid?] [normal-index exact-integer?]) solid?]
@defproc[(refine [value solid?] [count exact-nonnegative-integer?]) solid?]
@defproc[(refine-to-length [value solid?] [length real?]) solid?]
@defproc[(refine-to-tolerance [value solid?] [tolerance real?]) solid?]
@defproc[(simplify [value solid?] [tolerance real? 0]) solid?]

@section{Queries}

@defproc[(solid-empty? [value solid?]) boolean?]
@defproc[(solid-num-vertices [value solid?]) exact-nonnegative-integer?]
@defproc[(solid-num-edges [value solid?]) exact-nonnegative-integer?]
@defproc[(solid-num-triangles [value solid?]) exact-nonnegative-integer?]
@defproc[(solid-genus [value solid?]) exact-integer?]
@defproc[(solid-surface-area [value solid?]) real?]
@defproc[(solid-volume [value solid?]) real?]
@defproc[(solid-bounds [value solid?]) (values point3? point3?)]
@defproc[(solid-min-gap [value solid?] [other solid?] [search-length real?]) real?]
@defproc[(solid-winding-number [value solid?] [point (or/c point3? list? vector?)]) exact-integer?]
@defproc[(solid-ray-cast [value solid?] [origin (or/c list? vector?)]
                         [end (or/c list? vector?)]) (listof ray-hit?)]

@section{Meshes and Files}

@defproc[(solid->mesh [value solid?]) mesh?]
@defproc[(mesh->solid [value mesh?]) solid?]
@defproc[(write-stl [value solid?] [destination (or/c path-string? output-port?)]
                    [#:format format (or/c 'binary 'ascii) 'binary]
                    [#:name name string? "manifold"]) void?]
@defproc[(solid->stl-bytes [value solid?]
                           [#:format format (or/c 'binary 'ascii) 'binary]
                           [#:name name string? "manifold"]) bytes?]
@defproc[(read-obj [source (or/c string? input-port?)]) solid?]
@defproc[(read-obj-file [path path-string?]) solid?]
@defproc[(solid->obj-string [value solid?]) string?]
@defproc[(write-obj [value solid?]
                    [destination (or/c path-string? output-port?)]) void?]

@section{Errors and Native Information}

@defstruct*[(exn:fail:manifold exn:fail)
            ([operation symbol?] [status any/c]) #:transparent]
@defproc[(manifold-version) (list/c exact-integer? exact-integer? exact-integer?)]

@tt{manifold-library-path} is @racket[#f] before the first native operation and
then contains the candidate name or path used to load the native library.
Requiring the module is therefore safe on documentation and package-build
hosts where @tt{libmanifoldc} is absent.

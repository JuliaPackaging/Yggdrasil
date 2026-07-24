// cclipper2.h — C ABI for the Clipper2 polygon clipping and offsetting
// library (https://github.com/AngusJohnson/Clipper2), for FFI consumers such
// as Julia's ccall. Implemented by cclipper2.cpp (shipped as libcclipper2).
//
// SPDX-License-Identifier: BSL-1.0
// Distributed under the Boost Software License, Version 1.0.
// (See https://www.boost.org/LICENSE_1_0.txt)
//
// Interface conventions:
//   - Variable-length results are delivered through caller-supplied callbacks
//     (append(out, path_index, point) for flat path lists; newnode/append for
//     PolyTree walks), so the library never owns result memory.
//   - Engine handles come from clipper64_create / clipperoffset_create and
//     must be released with the matching *_delete.
//   - Enums cross the boundary as the int values below, which are owned by
//     this ABI and frozen (they are mapped to Clipper2's native enums
//     internally; upstream renumbering cannot silently remap operations).
//   - Errors: no C++ exception propagates across this ABI. Failures are
//     reported on stderr; mutating or result-producing calls return false
//     with no result emitted (this includes invalid enum values), the
//     constructors return NULL, and the pure geometry predicates return the
//     fallback documented at their declaration.
//   - The shipped libcclipper2 is compiled with Clipper2's USINGZ vertex
//     mode: every vertex carries a third int64 z. The narrow CPoint64 entry
//     points set z = 0 internally; the *_z entry points expose it for vertex
//     tagging/provenance. (A local non-USINGZ build of cclipper2.cpp simply
//     lacks the *_z symbols.)
//
// Enum values at the ABI boundary:
//   ClipType:  None=0, Intersection=1, Union=2, Difference=3, Xor=4
//   FillRule:  EvenOdd=0, NonZero=1, Positive=2, Negative=3
//   JoinType:  Square=0, Bevel=1, Round=2, Miter=3
//   EndType:   Polygon=0, Joined=1, Butt=2, Square=3, Round=4
//   PointInPolygonResult: IsOn=0, IsInside=1, IsOutside=2

#ifndef CCLIPPER2_H
#define CCLIPPER2_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CPoint64 {
    int64_t x;
    int64_t y;
} CPoint64;

// Wide point carrying the Clipper2 Z coordinate (see USINGZ note above).
typedef struct CPoint64Z {
    int64_t x;
    int64_t y;
    int64_t z;
} CPoint64Z;

// Opaque engine handles.
typedef struct clipper64 clipper64;
typedef struct clipperoffset clipperoffset;

// ==== Static / free functions ================================

// True for counter-clockwise / positive-area paths; false on error.
bool cclipper2_is_positive(const CPoint64 *path, size_t count);

// Signed area of the path; 0.0 on error.
double cclipper2_area(const CPoint64 *path, size_t count);

// PointInPolygonResult values: IsOn=0, IsInside=1, IsOutside=2 (also the
// error fallback).
int cclipper2_point_in_polygon(CPoint64 pt, const CPoint64 *path, size_t count);

// ==== Clipper64 engine (stateful boolean operations) =========

// Clipper2 defaults preserve_collinear=true; callers wanting minimal-vertex
// output (collinear vertices dropped) pass false. Returns NULL on error.
clipper64 *clipper64_create(bool preserve_collinear, bool reverse_solution);
void clipper64_delete(clipper64 *ptr);

// Single-path adds reject degenerate input (closed paths need >= 3 vertices,
// open >= 2) and return false; the batch variants pass everything through and
// leave degenerate-path handling to the engine.
bool clipper64_add_subject(clipper64 *ptr, const CPoint64 *path, size_t count);
bool clipper64_add_open_subject(clipper64 *ptr, const CPoint64 *path, size_t count);
bool clipper64_add_clip(clipper64 *ptr, const CPoint64 *path, size_t count);
bool clipper64_add_subjects(clipper64 *ptr, CPoint64 **paths,
                            size_t *path_counts, size_t count);
bool clipper64_add_open_subjects(clipper64 *ptr, CPoint64 **paths,
                                 size_t *path_counts, size_t count);
bool clipper64_add_clips(clipper64 *ptr, CPoint64 **paths,
                         size_t *path_counts, size_t count);

// clip_type: None=0, Intersection=1, Union=2, Difference=3, Xor=4.
// fill_rule: EvenOdd=0, NonZero=1, Positive=2, Negative=3 (applies to both
// subject and clip paths — Clipper2 uses a single fill rule).
// Closed solution paths go to (closed_out, append); open solution paths go to
// (open_out, append_open). Pass append_open = NULL to discard open paths.
bool clipper64_execute(clipper64 *ptr, int clip_type, int fill_rule,
                       void *closed_out,
                       void (*append)(void *, size_t, CPoint64),
                       void *open_out,
                       void (*append_open)(void *, size_t, CPoint64));

// PolyTree variant: closed contours arrive as a tree via newnode/append
// (newnode(parent, is_hole) returns the new child node; append(node, point)
// adds a contour vertex to it). Open paths arrive flat via append_open;
// pass NULL to discard them.
bool clipper64_execute_polytree(clipper64 *ptr, int clip_type, int fill_rule,
                                void *out_tree,
                                void *(*newnode)(void *, bool),
                                void (*append)(void *, CPoint64),
                                void *open_out,
                                void (*append_open)(void *, size_t, CPoint64));

void clipper64_clear(clipper64 *ptr);

// ==== ClipperOffset (polygon inflation/deflation) ============

// Returns NULL on error.
clipperoffset *clipperoffset_create(double miter_limit, double arc_tolerance,
                                    bool preserve_collinear,
                                    bool reverse_solution);
void clipperoffset_delete(clipperoffset *ptr);

// join_type: Square=0, Bevel=1, Round=2, Miter=3.
// end_type:  Polygon=0, Joined=1, Butt=2, Square=3, Round=4.
bool clipperoffset_add_path(clipperoffset *ptr, const CPoint64 *path,
                            size_t count, int join_type, int end_type);
bool clipperoffset_add_paths(clipperoffset *ptr, CPoint64 **paths,
                             size_t *path_counts, size_t count,
                             int join_type, int end_type);
void clipperoffset_clear(clipperoffset *ptr);
bool clipperoffset_execute(clipperoffset *ptr, double delta,
                           void *closed_out,
                           void (*append)(void *, size_t, CPoint64));

// ==== Utility functions ======================================

// Self-union: resolves self-intersections and merges overlapping contours
// (Union with no clip paths).
bool cclipper2_union_self(CPoint64 **paths, size_t *path_counts, size_t count,
                          int fill_rule, void *closed_out,
                          void (*append)(void *, size_t, CPoint64));

// Remove vertices that lie on the straight edge between their neighbours,
// per-path (no cross-path interaction). is_open applies to every path in the
// call; closed polygons pass false.
bool cclipper2_trim_collinear(CPoint64 **paths, size_t *path_counts,
                              size_t count, bool is_open, void *closed_out,
                              void (*append)(void *, size_t, CPoint64));

// Clip closed paths against an axis-aligned rectangle. Each path is clipped
// independently: results are NOT unioned, and subject hole/fill relationships
// are not resolved.
bool cclipper2_rect_clip(int64_t left, int64_t top, int64_t right,
                         int64_t bottom, CPoint64 **paths, size_t *path_counts,
                         size_t count, void *closed_out,
                         void (*append)(void *, size_t, CPoint64));

bool cclipper2_minkowski_sum(const CPoint64 *pattern, size_t n1,
                             const CPoint64 *path, size_t n2,
                             void *closed_out,
                             void (*append)(void *, size_t, CPoint64),
                             bool is_closed);
bool cclipper2_minkowski_difference(const CPoint64 *pattern, size_t n1,
                                    const CPoint64 *path, size_t n2,
                                    void *closed_out,
                                    void (*append)(void *, size_t, CPoint64),
                                    bool is_closed);

// ==== Z-aware API ============================================
//
// These entry points let a caller tag each input vertex's z with an
// application-defined value (e.g. a source-geometry id) and read back the z
// of every output vertex — including the vertices Clipper2 *invents* at
// edge–edge intersections, which are stamped with the sentinel INT64_MIN.
// Vertices where the intersection point coincides with an input vertex keep
// that vertex's z (subject endpoints take priority over clip).

// z-carrying add variants. Same degenerate-path policy as the narrow API:
// single-path adds reject short paths, batch variants pass through.
bool clipper64_add_subject_z(clipper64 *ptr, const CPoint64Z *path, size_t count);
bool clipper64_add_open_subject_z(clipper64 *ptr, const CPoint64Z *path, size_t count);
bool clipper64_add_clip_z(clipper64 *ptr, const CPoint64Z *path, size_t count);
bool clipper64_add_subjects_z(clipper64 *ptr, CPoint64Z **paths,
                              size_t *path_counts, size_t count);
bool clipper64_add_open_subjects_z(clipper64 *ptr, CPoint64Z **paths,
                                   size_t *path_counts, size_t count);
bool clipper64_add_clips_z(clipper64 *ptr, CPoint64Z **paths,
                           size_t *path_counts, size_t count);

// z-carrying PolyTree execute (the flat-paths variant is deliberately not
// provided; adding one later is a new symbol, not an ABI break).
bool clipper64_execute_polytree_z(clipper64 *ptr, int clip_type, int fill_rule,
                                  void *out_tree,
                                  void *(*newnode)(void *, bool),
                                  void (*append)(void *, CPoint64Z),
                                  void *open_out,
                                  void (*append_open)(void *, size_t, CPoint64Z));

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CCLIPPER2_H

// cclipper2.cpp — C ABI for the Clipper2 polygon clipping and offsetting
// library (https://github.com/AngusJohnson/Clipper2), for FFI consumers such
// as Julia's ccall. The interface contract — calling conventions, ownership,
// error reporting, and the frozen enum values — is documented in cclipper2.h,
// which is installed alongside Clipper2's own headers.
//
// SPDX-License-Identifier: BSL-1.0
// Distributed under the Boost Software License, Version 1.0.
// (See https://www.boost.org/LICENSE_1_0.txt)
//
// Implementation notes:
//   - Enums cross the boundary as the wrapper-owned int values in cclipper2.h,
//     mapped to Clipper2's native enums with switch statements — upstream
//     renumbering (which has happened before in a patch version bump) cannot
//     silently remap operations.
//   - Every exported function body runs inside a guarded()/guarded_void()
//     barrier, so no C++ exception can cross the C ABI (that is undefined
//     behavior — in practice std::terminate). The barrier must enclose
//     argument marshalling too: to_path64/to_paths64 allocate and can throw
//     before any engine call runs.
//   - Build contract: compile with -DUSINGZ and link libClipper2Z. Point64
//     then carries a third int64 z; the narrow {x,y} entry points construct
//     it with z=0, and the *_z entry points expose it. (The file also
//     compiles without USINGZ against libClipper2, minus the *_z entry
//     points.)

#include "cclipper2.h"

#include "clipper2/clipper.h"
#include <cstdio>
#include <cstdint>
#include <exception>

#if defined _WIN32 || defined __CYGWIN__
  #ifdef __GNUC__
    #define CDECL __attribute__((cdecl))
    #define DLL_PUBLIC __attribute__((dllexport))
  #else
    #define CDECL __cdecl
    #define DLL_PUBLIC __declspec(dllexport)
  #endif
#else
  #define CDECL __attribute__((cdecl))
  #if __GNUC__ >= 4
    #define DLL_PUBLIC __attribute__((visibility("default")))
  #else
    #define DLL_PUBLIC
  #endif
#endif

// ============================================================
// Opaque handles — cclipper2.h's clipper64 / clipperoffset are
// pointer-punned engine objects; they are never dereferenced as
// their C struct types.
// ============================================================
static Clipper2Lib::Clipper64 *engine(clipper64 *ptr)
{
    return reinterpret_cast<Clipper2Lib::Clipper64 *>(ptr);
}

static Clipper2Lib::ClipperOffset *engine(clipperoffset *ptr)
{
    return reinterpret_cast<Clipper2Lib::ClipperOffset *>(ptr);
}

// ============================================================
// Exception barrier. Reports on stderr and returns the fallback value; the
// catch (...) arm keeps the barrier complete for exceptions not derived from
// std::exception.
// ============================================================
template <typename T, typename F>
static T guarded(T fallback, F &&fn)
{
    try {
        return fn();
    } catch (const std::exception &e) {
        fprintf(stderr, "cclipper2: %s\n", e.what());
    } catch (...) {
        fprintf(stderr, "cclipper2: unknown C++ exception\n");
    }
    return fallback;
}

template <typename F>
static void guarded_void(F &&fn)
{
    guarded(false, [&] { fn(); return true; });
}

// ============================================================
// Enum mapping — wrapper-owned ABI values (cclipper2.h) to Clipper2's native
// enums. Unknown values report on stderr and return false, so callers fail
// loudly instead of running a default operation on wrong geometry.
// ============================================================
static bool to_cliptype(int v, Clipper2Lib::ClipType &out)
{
    using CT = Clipper2Lib::ClipType;
    switch (v) {
        case 0: out = CT::NoClip;       return true;
        case 1: out = CT::Intersection; return true;
        case 2: out = CT::Union;        return true;
        case 3: out = CT::Difference;   return true;
        case 4: out = CT::Xor;          return true;
    }
    fprintf(stderr, "cclipper2: invalid ClipType %d\n", v);
    return false;
}

static bool to_fillrule(int v, Clipper2Lib::FillRule &out)
{
    using FR = Clipper2Lib::FillRule;
    switch (v) {
        case 0: out = FR::EvenOdd;  return true;
        case 1: out = FR::NonZero;  return true;
        case 2: out = FR::Positive; return true;
        case 3: out = FR::Negative; return true;
    }
    fprintf(stderr, "cclipper2: invalid FillRule %d\n", v);
    return false;
}

static bool to_jointype(int v, Clipper2Lib::JoinType &out)
{
    using JT = Clipper2Lib::JoinType;
    switch (v) {
        case 0: out = JT::Square; return true;
        case 1: out = JT::Bevel;  return true;
        case 2: out = JT::Round;  return true;
        case 3: out = JT::Miter;  return true;
    }
    fprintf(stderr, "cclipper2: invalid JoinType %d\n", v);
    return false;
}

static bool to_endtype(int v, Clipper2Lib::EndType &out)
{
    using ET = Clipper2Lib::EndType;
    switch (v) {
        case 0: out = ET::Polygon; return true;
        case 1: out = ET::Joined;  return true;
        case 2: out = ET::Butt;    return true;
        case 3: out = ET::Square;  return true;
        case 4: out = ET::Round;   return true;
    }
    fprintf(stderr, "cclipper2: invalid EndType %d\n", v);
    return false;
}

static int from_pip(Clipper2Lib::PointInPolygonResult r)
{
    using PIP = Clipper2Lib::PointInPolygonResult;
    switch (r) {
        case PIP::IsOn:      return 0;
        case PIP::IsInside:  return 1;
        case PIP::IsOutside: return 2;
    }
    return 2; // unreachable; treat as outside
}

// ============================================================
// Internal helpers
// ============================================================
static Clipper2Lib::Path64 to_path64(const CPoint64 *pts, size_t count)
{
    Clipper2Lib::Path64 path;
    path.reserve(count);
    for (size_t i = 0; i < count; i++)
        path.emplace_back(pts[i].x, pts[i].y);
    return path;
}

static Clipper2Lib::Paths64 to_paths64(CPoint64 **paths, size_t *counts, size_t n)
{
    Clipper2Lib::Paths64 result;
    result.reserve(n);
    for (size_t i = 0; i < n; i++)
        result.push_back(to_path64(paths[i], counts[i]));
    return result;
}

static void send_paths(const Clipper2Lib::Paths64 &paths,
                        void *output,
                        void (*append)(void *, size_t, CPoint64))
{
    for (size_t i = 0; i < paths.size(); i++)
        for (const auto &pt : paths[i])
            append(output, i, CPoint64{pt.x, pt.y});
}

// PolyTree nodes carry closed contours only; open paths are returned
// separately by Execute (delivered via the append_open callbacks below).
static void populatenode(const Clipper2Lib::PolyPath64 &node,
                          void *out_node,
                          void *(*newnode)(void *, bool),
                          void (*append)(void *, CPoint64))
{
    for (const auto &pt : node.Polygon())
        append(out_node, CPoint64{pt.x, pt.y});

    for (size_t i = 0; i < node.Count(); i++)
    {
        const auto *child = node.Child(i);
        void *out_child = newnode(out_node, child->IsHole());
        populatenode(*child, out_child, newnode, append);
    }
}

enum class AddMode { Subject, OpenSubject, Clip };

static void add_paths_impl(Clipper2Lib::Clipper64 *ptr,
                           const Clipper2Lib::Paths64 &paths, AddMode mode)
{
    switch (mode) {
        case AddMode::Subject:     ptr->AddSubject(paths); break;
        case AddMode::OpenSubject: ptr->AddOpenSubject(paths); break;
        case AddMode::Clip:        ptr->AddClip(paths); break;
    }
}

// ============================================================
extern "C" {
// ============================================================

// ==== Static / free functions ================================

DLL_PUBLIC bool CDECL cclipper2_is_positive(const CPoint64 *path, size_t count)
{
    return guarded(false, [&] {
        return Clipper2Lib::IsPositive(to_path64(path, count));
    });
}

DLL_PUBLIC double CDECL cclipper2_area(const CPoint64 *path, size_t count)
{
    return guarded(0.0, [&] {
        return Clipper2Lib::Area(to_path64(path, count));
    });
}

DLL_PUBLIC int CDECL cclipper2_point_in_polygon(CPoint64 pt, const CPoint64 *path,
                                                 size_t count)
{
    return guarded(2 /* IsOutside */, [&] {
        Clipper2Lib::Point64 p(pt.x, pt.y);
        return from_pip(Clipper2Lib::PointInPolygon(p, to_path64(path, count)));
    });
}

// ==== Clipper64 engine (stateful boolean operations) =========

DLL_PUBLIC clipper64 *CDECL clipper64_create(bool preserve_collinear,
                                              bool reverse_solution)
{
    return guarded(static_cast<clipper64 *>(nullptr), [&] {
        auto *c = new Clipper2Lib::Clipper64();
        c->PreserveCollinear(preserve_collinear);
        c->ReverseSolution(reverse_solution);
        return reinterpret_cast<clipper64 *>(c);
    });
}

DLL_PUBLIC void CDECL clipper64_delete(clipper64 *ptr)
{
    guarded_void([&] { delete engine(ptr); });
}

DLL_PUBLIC bool CDECL clipper64_add_subject(clipper64 *ptr,
                                             const CPoint64 *path, size_t count)
{
    if (count < 3) return false;
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), {to_path64(path, count)}, AddMode::Subject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_open_subject(clipper64 *ptr,
                                                  const CPoint64 *path, size_t count)
{
    if (count < 2) return false;
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), {to_path64(path, count)}, AddMode::OpenSubject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_clip(clipper64 *ptr,
                                          const CPoint64 *path, size_t count)
{
    if (count < 3) return false;
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), {to_path64(path, count)}, AddMode::Clip);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_subjects(clipper64 *ptr,
                                              CPoint64 **paths, size_t *path_counts,
                                              size_t count)
{
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), to_paths64(paths, path_counts, count),
                       AddMode::Subject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_open_subjects(clipper64 *ptr,
                                                   CPoint64 **paths, size_t *path_counts,
                                                   size_t count)
{
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), to_paths64(paths, path_counts, count),
                       AddMode::OpenSubject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_clips(clipper64 *ptr,
                                           CPoint64 **paths, size_t *path_counts,
                                           size_t count)
{
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), to_paths64(paths, path_counts, count),
                       AddMode::Clip);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_execute(clipper64 *ptr,
                                         int clip_type, int fill_rule,
                                         void *closed_out,
                                         void (*append)(void *, size_t, CPoint64),
                                         void *open_out,
                                         void (*append_open)(void *, size_t, CPoint64))
{
    return guarded(false, [&] {
        Clipper2Lib::ClipType ct;
        Clipper2Lib::FillRule fr;
        if (!to_cliptype(clip_type, ct) || !to_fillrule(fill_rule, fr))
            return false;

        Clipper2Lib::Paths64 solution;
        Clipper2Lib::Paths64 open_solution;
        if (!engine(ptr)->Execute(ct, fr, solution, open_solution))
            return false;

        send_paths(solution, closed_out, append);
        if (append_open != nullptr)
            send_paths(open_solution, open_out, append_open);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_execute_polytree(clipper64 *ptr,
                                                  int clip_type, int fill_rule,
                                                  void *out_tree,
                                                  void *(*newnode)(void *, bool),
                                                  void (*append)(void *, CPoint64),
                                                  void *open_out,
                                                  void (*append_open)(void *, size_t, CPoint64))
{
    return guarded(false, [&] {
        Clipper2Lib::ClipType ct;
        Clipper2Lib::FillRule fr;
        if (!to_cliptype(clip_type, ct) || !to_fillrule(fill_rule, fr))
            return false;

        Clipper2Lib::PolyTree64 pt;
        Clipper2Lib::Paths64 open_paths;
        if (!engine(ptr)->Execute(ct, fr, pt, open_paths))
            return false;

        for (size_t i = 0; i < pt.Count(); i++)
        {
            const auto *child = pt.Child(i);
            void *out_node = newnode(out_tree, child->IsHole());
            populatenode(*child, out_node, newnode, append);
        }
        if (append_open != nullptr)
            send_paths(open_paths, open_out, append_open);
        return true;
    });
}

DLL_PUBLIC void CDECL clipper64_clear(clipper64 *ptr)
{
    guarded_void([&] { engine(ptr)->Clear(); });
}

// ==== ClipperOffset (polygon inflation/deflation) ============

DLL_PUBLIC clipperoffset *CDECL clipperoffset_create(double miter_limit,
                                                      double arc_tolerance,
                                                      bool preserve_collinear,
                                                      bool reverse_solution)
{
    return guarded(static_cast<clipperoffset *>(nullptr), [&] {
        auto *c = new Clipper2Lib::ClipperOffset(miter_limit, arc_tolerance,
                                                 preserve_collinear,
                                                 reverse_solution);
        return reinterpret_cast<clipperoffset *>(c);
    });
}

DLL_PUBLIC void CDECL clipperoffset_delete(clipperoffset *ptr)
{
    guarded_void([&] { delete engine(ptr); });
}

DLL_PUBLIC bool CDECL clipperoffset_add_path(clipperoffset *ptr,
                                              const CPoint64 *path, size_t count,
                                              int join_type, int end_type)
{
    return guarded(false, [&] {
        Clipper2Lib::JoinType jt;
        Clipper2Lib::EndType et;
        if (!to_jointype(join_type, jt) || !to_endtype(end_type, et))
            return false;

        engine(ptr)->AddPath(to_path64(path, count), jt, et);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipperoffset_add_paths(clipperoffset *ptr,
                                               CPoint64 **paths, size_t *path_counts,
                                               size_t count, int join_type, int end_type)
{
    return guarded(false, [&] {
        Clipper2Lib::JoinType jt;
        Clipper2Lib::EndType et;
        if (!to_jointype(join_type, jt) || !to_endtype(end_type, et))
            return false;

        engine(ptr)->AddPaths(to_paths64(paths, path_counts, count), jt, et);
        return true;
    });
}

DLL_PUBLIC void CDECL clipperoffset_clear(clipperoffset *ptr)
{
    guarded_void([&] { engine(ptr)->Clear(); });
}

DLL_PUBLIC bool CDECL clipperoffset_execute(clipperoffset *ptr, double delta,
                                             void *closed_out,
                                             void (*append)(void *, size_t, CPoint64))
{
    return guarded(false, [&] {
        Clipper2Lib::Paths64 solution;
        engine(ptr)->Execute(delta, solution);
        send_paths(solution, closed_out, append);
        return true;
    });
}

// ==== Utility functions ======================================

// Self-union (Union with no clip paths). Named distinctly from Clipper2's
// SimplifyPaths, which is a different algorithm (perpendicular-distance
// vertex reduction).
DLL_PUBLIC bool CDECL cclipper2_union_self(CPoint64 **paths, size_t *path_counts,
                                            size_t count, int fill_rule,
                                            void *closed_out,
                                            void (*append)(void *, size_t, CPoint64))
{
    return guarded(false, [&] {
        Clipper2Lib::FillRule fr;
        if (!to_fillrule(fill_rule, fr))
            return false;

        Clipper2Lib::Clipper64 clipper;
        clipper.AddSubject(to_paths64(paths, path_counts, count));
        Clipper2Lib::Paths64 output;
        if (!clipper.Execute(Clipper2Lib::ClipType::Union, fr, output))
            return false;

        send_paths(output, closed_out, append);
        return true;
    });
}

// Per-path TrimCollinear; useful for callers wanting minimal-vertex contours
// from an engine run with PreserveCollinear=true.
DLL_PUBLIC bool CDECL cclipper2_trim_collinear(CPoint64 **paths, size_t *path_counts,
                                                size_t count, bool is_open,
                                                void *closed_out,
                                                void (*append)(void *, size_t, CPoint64))
{
    return guarded(false, [&] {
        auto input = to_paths64(paths, path_counts, count);
        Clipper2Lib::Paths64 output;
        output.reserve(input.size());
        for (const auto &p : input)
            output.push_back(Clipper2Lib::TrimCollinear(p, is_open));
        send_paths(output, closed_out, append);
        return true;
    });
}

// Clipper2's RectClip: O(n) per path vs a full sweep-line boolean; a
// tile-cutting primitive.
DLL_PUBLIC bool CDECL cclipper2_rect_clip(int64_t left, int64_t top,
                                           int64_t right, int64_t bottom,
                                           CPoint64 **paths, size_t *path_counts,
                                           size_t count,
                                           void *closed_out,
                                           void (*append)(void *, size_t, CPoint64))
{
    return guarded(false, [&] {
        Clipper2Lib::Rect64 rect(left, top, right, bottom);
        auto output = Clipper2Lib::RectClip(rect,
                                            to_paths64(paths, path_counts, count));
        send_paths(output, closed_out, append);
        return true;
    });
}

DLL_PUBLIC bool CDECL cclipper2_minkowski_sum(const CPoint64 *pattern, size_t n1,
                                               const CPoint64 *path, size_t n2,
                                               void *closed_out,
                                               void (*append)(void *, size_t, CPoint64),
                                               bool is_closed)
{
    return guarded(false, [&] {
        auto result = Clipper2Lib::MinkowskiSum(
            to_path64(pattern, n1), to_path64(path, n2), is_closed);
        send_paths(result, closed_out, append);
        return true;
    });
}

DLL_PUBLIC bool CDECL cclipper2_minkowski_difference(const CPoint64 *pattern, size_t n1,
                                                      const CPoint64 *path, size_t n2,
                                                      void *closed_out,
                                                      void (*append)(void *, size_t, CPoint64),
                                                      bool is_closed)
{
    return guarded(false, [&] {
        auto result = Clipper2Lib::MinkowskiDiff(
            to_path64(pattern, n1), to_path64(path, n2), is_closed);
        send_paths(result, closed_out, append);
        return true;
    });
}

// ==== Z-aware API (USINGZ build only) ========================
//
// Point64 carries a third int64 `z` in the USINGZ build. These entry points
// let a caller tag each input vertex's z with an application-defined value
// (e.g. a source-geometry id) and read back the z of every output vertex —
// including the vertices Clipper2 *invents* at edge–edge intersections, which
// the engine stamps with the sentinel below (via DefaultZ). That turns "which
// input vertex does this output vertex correspond to" from a geometric search
// into a lookup. The narrow ({x,y}) API above is unchanged in this build
// (z = 0 internally).
#ifdef USINGZ

// Marks a vertex created by Clipper2 at an edge–edge intersection (as opposed
// to one of the caller's tagged input vertices). Chosen at the far end of the
// int64 range to stay clear of application id spaces.
static const int64_t Z_INTERSECTION = INT64_MIN;

static Clipper2Lib::Path64 to_path64z(const CPoint64Z *pts, size_t count)
{
    Clipper2Lib::Path64 path;
    path.reserve(count);
    for (size_t i = 0; i < count; i++)
        path.emplace_back(pts[i].x, pts[i].y, pts[i].z);
    return path;
}

static Clipper2Lib::Paths64 to_paths64z(CPoint64Z **paths, size_t *counts, size_t n)
{
    Clipper2Lib::Paths64 result;
    result.reserve(n);
    for (size_t i = 0; i < n; i++)
        result.push_back(to_path64z(paths[i], counts[i]));
    return result;
}

static void send_paths_z(const Clipper2Lib::Paths64 &paths,
                          void *output,
                          void (*append)(void *, size_t, CPoint64Z))
{
    for (size_t i = 0; i < paths.size(); i++)
        for (const auto &pt : paths[i])
            append(output, i, CPoint64Z{pt.x, pt.y, pt.z});
}

// Clipper2's SetZ pre-seeds an intersection vertex's z before invoking the
// registered callback: when the intersection point coincides with one of the
// four edge endpoints it copies that endpoint's z (subject endpoints take
// priority over clip), otherwise it assigns the engine's DefaultZ. Setting
// DefaultZ to the sentinel and registering this callback that leaves pt.z
// untouched therefore stamps exactly the truly-invented vertices — a callback
// stamping unconditionally would clobber the endpoint-coincident case.
// Registration is still required: with no callback SetZ returns early and
// invented vertices get z = 0, indistinguishable from a tagged input vertex.
// Callers wanting richer intersection semantics (e.g. deriving z from the
// four contributing edge endpoints) can register their own policy instead.
static void noop_zcb(const Clipper2Lib::Point64 & /*e1bot*/,
                     const Clipper2Lib::Point64 & /*e1top*/,
                     const Clipper2Lib::Point64 & /*e2bot*/,
                     const Clipper2Lib::Point64 & /*e2top*/,
                     Clipper2Lib::Point64 & /*pt*/)
{
}

// The narrow tree walk (populatenode) emitting z.
static void populatenode_z(const Clipper2Lib::PolyPath64 &node,
                            void *out_node,
                            void *(*newnode)(void *, bool),
                            void (*append)(void *, CPoint64Z))
{
    for (const auto &pt : node.Polygon())
        append(out_node, CPoint64Z{pt.x, pt.y, pt.z});

    for (size_t i = 0; i < node.Count(); i++)
    {
        const auto *child = node.Child(i);
        void *out_child = newnode(out_node, child->IsHole());
        populatenode_z(*child, out_child, newnode, append);
    }
}

DLL_PUBLIC bool CDECL clipper64_add_subject_z(clipper64 *ptr,
                                               const CPoint64Z *path, size_t count)
{
    if (count < 3) return false;
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), {to_path64z(path, count)}, AddMode::Subject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_open_subject_z(clipper64 *ptr,
                                                    const CPoint64Z *path, size_t count)
{
    if (count < 2) return false;
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), {to_path64z(path, count)}, AddMode::OpenSubject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_clip_z(clipper64 *ptr,
                                            const CPoint64Z *path, size_t count)
{
    if (count < 3) return false;
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), {to_path64z(path, count)}, AddMode::Clip);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_subjects_z(clipper64 *ptr,
                                                CPoint64Z **paths, size_t *path_counts,
                                                size_t count)
{
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), to_paths64z(paths, path_counts, count),
                       AddMode::Subject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_open_subjects_z(clipper64 *ptr,
                                                     CPoint64Z **paths, size_t *path_counts,
                                                     size_t count)
{
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), to_paths64z(paths, path_counts, count),
                       AddMode::OpenSubject);
        return true;
    });
}

DLL_PUBLIC bool CDECL clipper64_add_clips_z(clipper64 *ptr,
                                             CPoint64Z **paths, size_t *path_counts,
                                             size_t count)
{
    return guarded(false, [&] {
        add_paths_impl(engine(ptr), to_paths64z(paths, path_counts, count),
                       AddMode::Clip);
        return true;
    });
}

// z-carrying PolyTree execute. Arms the sentinel policy (DefaultZ + no-op
// callback, see noop_zcb above) so intersection-created vertices are stamped
// and endpoint-coincident ones keep their input z, then walks the tree
// emitting CPoint64Z (x,y,z).
DLL_PUBLIC bool CDECL clipper64_execute_polytree_z(clipper64 *ptr,
                                                    int clip_type, int fill_rule,
                                                    void *out_tree,
                                                    void *(*newnode)(void *, bool),
                                                    void (*append)(void *, CPoint64Z),
                                                    void *open_out,
                                                    void (*append_open)(void *, size_t, CPoint64Z))
{
    return guarded(false, [&] {
        Clipper2Lib::ClipType ct;
        Clipper2Lib::FillRule fr;
        if (!to_cliptype(clip_type, ct) || !to_fillrule(fill_rule, fr))
            return false;

        engine(ptr)->DefaultZ = Z_INTERSECTION;
        engine(ptr)->SetZCallback(noop_zcb);

        Clipper2Lib::PolyTree64 pt;
        Clipper2Lib::Paths64 open_paths;
        if (!engine(ptr)->Execute(ct, fr, pt, open_paths))
            return false;

        for (size_t i = 0; i < pt.Count(); i++) {
            const auto *child = pt.Child(i);
            void *out_node = newnode(out_tree, child->IsHole());
            populatenode_z(*child, out_node, newnode, append);
        }
        if (append_open != nullptr)
            send_paths_z(open_paths, open_out, append_open);
        return true;
    });
}

#endif // USINGZ

} // extern "C"

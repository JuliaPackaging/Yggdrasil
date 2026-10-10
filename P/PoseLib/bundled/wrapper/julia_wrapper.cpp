// =============================================================================
// PoseLib Julia Wrapper
// =============================================================================
//
// Thin C wrapper around PoseLib minimal solvers for Julia ccall.
// All functions use flat double arrays (column-major for matrices).
//
// Conventions:
//   - Points are arrays of 3 doubles (homogeneous 2D or 3D)
//   - 3x3 matrices are 9 doubles in column-major order (Eigen default)
//   - Poses are 12 doubles: R (9, col-major) then t (3)
//   - Return value = number of solutions (0 on failure)
//
// =============================================================================

#include <Eigen/Dense>
#include <vector>
#include <cstring>

#include "PoseLib/solvers/homography_4pt.h"
#include "PoseLib/solvers/relpose_5pt.h"
#include "PoseLib/solvers/relpose_7pt.h"
#include "PoseLib/solvers/relpose_8pt.h"
#include "PoseLib/solvers/p3p.h"
#include "PoseLib/misc/decompositions.h"
#include "PoseLib/robust/bundle.h"

// Helper: read n points from flat array into vector<Vector3d>
static std::vector<Eigen::Vector3d> read_points(const double *data, int n) {
    std::vector<Eigen::Vector3d> pts(n);
    for (int i = 0; i < n; i++) {
        pts[i] = Eigen::Vector3d(data[3*i], data[3*i+1], data[3*i+2]);
    }
    return pts;
}

// Helper: write 3x3 matrix to flat array (column-major, matching Eigen default)
static void write_matrix(double *dst, const Eigen::Matrix3d &M) {
    std::memcpy(dst, M.data(), 9 * sizeof(double));
}

// Helper: write pose (R, t) to flat array: 9 doubles for R + 3 doubles for t
static void write_pose(double *dst, const poselib::CameraPose &pose) {
    Eigen::Matrix3d R = pose.R();
    std::memcpy(dst, R.data(), 9 * sizeof(double));
    std::memcpy(dst + 9, pose.t.data(), 3 * sizeof(double));
}

// ---------------------------------------------------------------------------
// SHIM NAMING CONVENTION (shared with lib/RansacLibLO's julia_wrapper.cpp):
//   C symbols:  <lib>_<upstream free-function name>  (e.g. poselib_refine_fundamental
//               mirrors poselib::refine_fundamental);  <lib>_<algorithm name> only
//               when the entry composes upstream internals with no free
//               function of their own (e.g. ransaclib_lebeda_lo).
//   Julia API:  task verbs refine_<model> for single-model refinement;
//               algorithm names for algorithm drivers; where the Julia verb
//               and the upstream name diverge, the package carries an
//               unexported upstream-faithful alias (PoseLib.bundle_adjust).
// ---------------------------------------------------------------------------
// Here: where one upstream name has several overloads, the symbol carries the
// overload's suffix — _cam for the Image/ImagePair forms, _bearing for the
// (d, M) form. The z = 1 chart overloads are not wrapped (see bundle_adjust_cam).
extern "C" {

// -------------------------------------------------------------------------
// homography_4pt
// -------------------------------------------------------------------------
// x1, x2: 4 points each, 12 doubles (homogeneous)
// H_out: 9 doubles (column-major 3x3)
// Returns: 0 or 1
int poselib_homography_4pt(const double *x1, const double *x2,
                           double *H_out, int check_cheirality) {
    auto p1 = read_points(x1, 4);
    auto p2 = read_points(x2, 4);
    Eigen::Matrix3d H;
    int n = poselib::homography_4pt(p1, p2, &H, check_cheirality != 0);
    if (n > 0) {
        write_matrix(H_out, H);
    }
    return n;
}

// -------------------------------------------------------------------------
// relpose_5pt  (essential matrices)
// -------------------------------------------------------------------------
// x1, x2: 5 points each, 15 doubles (bearing vectors)
// E_out: up to max_out matrices, 9*max_out doubles pre-allocated
// Returns: number of solutions (0..10)
int poselib_relpose_5pt(const double *x1, const double *x2,
                        double *E_out, int max_out) {
    auto p1 = read_points(x1, 5);
    auto p2 = read_points(x2, 5);
    std::vector<Eigen::Matrix3d> Es;
    int n = poselib::relpose_5pt(p1, p2, &Es);
    int out = (n < max_out) ? n : max_out;
    for (int i = 0; i < out; i++) {
        write_matrix(E_out + 9*i, Es[i]);
    }
    return out;
}

// -------------------------------------------------------------------------
// relpose_7pt  (fundamental matrices)
// -------------------------------------------------------------------------
// x1, x2: 7 points each, 21 doubles (pixel homogeneous)
// F_out: up to max_out matrices, 9*max_out doubles pre-allocated
// Returns: number of solutions (0..3)
int poselib_relpose_7pt(const double *x1, const double *x2,
                        double *F_out, int max_out) {
    auto p1 = read_points(x1, 7);
    auto p2 = read_points(x2, 7);
    std::vector<Eigen::Matrix3d> Fs;
    int n = poselib::relpose_7pt(p1, p2, &Fs);
    int out = (n < max_out) ? n : max_out;
    for (int i = 0; i < out; i++) {
        write_matrix(F_out + 9*i, Fs[i]);
    }
    return out;
}

// -------------------------------------------------------------------------
// essential_matrix_8pt  (single essential matrix, linear)
// -------------------------------------------------------------------------
// x1, x2: n bearing vectors, n*3 doubles each
// E_out: 9 doubles (column-major 3x3)
// Returns: 1 always (void function in PoseLib)
int poselib_essential_8pt(const double *x1, const double *x2, int npts,
                          double *E_out) {
    auto p1 = read_points(x1, npts);
    auto p2 = read_points(x2, npts);
    Eigen::Matrix3d E;
    poselib::essential_matrix_8pt(p1, p2, &E);
    write_matrix(E_out, E);
    return 1;
}

// -------------------------------------------------------------------------
// p3p  (absolute pose from 3 point correspondences)
// -------------------------------------------------------------------------
// x: 3 bearing vectors, 9 doubles
// X: 3 world points, 9 doubles
// poses_out: up to max_out poses, each 12 doubles (R + t), 12*max_out total
// Returns: number of solutions (0..4)
int poselib_p3p(const double *x, const double *X,
                double *poses_out, int max_out) {
    auto bearing = read_points(x, 3);
    auto world = read_points(X, 3);
    std::vector<poselib::CameraPose> poses;
    int n = poselib::p3p(bearing, world, &poses);
    int out = (n < max_out) ? n : max_out;
    for (int i = 0; i < out; i++) {
        write_pose(poses_out + 12*i, poses[i]);
    }
    return out;
}

// -------------------------------------------------------------------------
// motion_from_homography  (up to 4 (R, t, n) candidates)
// -------------------------------------------------------------------------
// H:           9 doubles (column-major 3x3, calibrated: K2^{-1} H K1 already applied)
// Rs_out:      9*max_out doubles, up to max_out rotations (column-major)
// ts_out:      3*max_out doubles, up to max_out translation vectors
// ns_out:      3*max_out doubles, up to max_out plane normals
// max_out:     caller-provided buffer capacity (use 4 to be safe)
// Returns:     number of candidates written (0..4; 1 for pure rotation)
int poselib_motion_from_homography(const double *H,
                                    double *Rs_out, double *ts_out,
                                    double *ns_out, int max_out) {
    Eigen::Map<const Eigen::Matrix3d> H_mat(H);
    std::vector<poselib::CameraPose> poses;
    std::vector<Eigen::Vector3d> normals;
    poselib::motion_from_homography(H_mat, &poses, &normals);
    int n = static_cast<int>(poses.size());
    int out = (n < max_out) ? n : max_out;
    for (int i = 0; i < out; i++) {
        Eigen::Matrix3d R = poses[i].R();
        std::memcpy(Rs_out + 9*i, R.data(), 9 * sizeof(double));
        std::memcpy(ts_out + 3*i, poses[i].t.data(), 3 * sizeof(double));
        std::memcpy(ns_out + 3*i, normals[i].data(), 3 * sizeof(double));
    }
    return out;
}

// -------------------------------------------------------------------------
// refine_fundamental  (robust-loss LM bundle on a fundamental matrix)
// -------------------------------------------------------------------------
// Optimizes the Sampson error over the Bartoli–Sturm SVD factorization of F
// (poselib::refine_fundamental, bundle.cc).
// x1, x2:     npts 2D points each, 2*npts doubles (pixel coords)
// F_in:       seed fundamental matrix — 9 doubles (column-major 3x3)
// loss_scale: the loss width (Julia `loss_width`), Sampson residual units
// max_iter:   LM iterations
// F_out:      refined fundamental matrix — 9 doubles (column-major 3x3)
// Returns:    number of LM iterations taken (BundleStats.iterations)
int poselib_refine_fundamental(const double *x1, const double *x2, int npts,
                               const double *F_in,
                               double loss_scale, int max_iter, int loss_type,
                               double *F_out) {
    std::vector<poselib::Point2D> p1(npts), p2(npts);
    for (int i = 0; i < npts; i++) {
        p1[i] = Eigen::Vector2d(x1[2*i], x1[2*i+1]);
        p2[i] = Eigen::Vector2d(x2[2*i], x2[2*i+1]);
    }
    Eigen::Matrix3d F = Eigen::Map<const Eigen::Matrix3d>(F_in);

    poselib::BundleOptions opt;
    opt.loss_type = static_cast<poselib::BundleOptions::LossType>(loss_type);
    opt.loss_scale = loss_scale;
    opt.max_iterations = static_cast<size_t>(max_iter);

    poselib::BundleStats stats = poselib::refine_fundamental(p1, p2, &F, opt);

    std::memcpy(F_out, F.data(), 9 * sizeof(double));
    return static_cast<int>(stats.iterations);
}

// -------------------------------------------------------------------------
// refine_homography  (robust-loss LM bundle on a homography)
// -------------------------------------------------------------------------
// Optimizes the symmetric transfer error — forward |x2 - pi(H*x1)| and
// backward |x1 - pi(adj(H)*x2)|, each side robustified per point
// (poselib::refine_homography, bundle.cc / PinholeHomographyRefiner).
// x1, x2:     npts 2D points each, 2*npts doubles (pixel coords)
// H_in:       seed homography — 9 doubles (column-major 3x3)
// loss_scale: the loss width (Julia `loss_width`), transfer-error units
// max_iter:   LM iterations
// H_out:      refined homography — 9 doubles (column-major 3x3)
// Returns:    number of LM iterations taken (BundleStats.iterations)
int poselib_refine_homography(const double *x1, const double *x2, int npts,
                              const double *H_in,
                              double loss_scale, int max_iter, int loss_type,
                              double *H_out) {
    std::vector<poselib::Point2D> p1(npts), p2(npts);
    for (int i = 0; i < npts; i++) {
        p1[i] = Eigen::Vector2d(x1[2*i], x1[2*i+1]);
        p2[i] = Eigen::Vector2d(x2[2*i], x2[2*i+1]);
    }
    Eigen::Matrix3d H = Eigen::Map<const Eigen::Matrix3d>(H_in);

    poselib::BundleOptions opt;
    opt.loss_type = static_cast<poselib::BundleOptions::LossType>(loss_type);
    opt.loss_scale = loss_scale;
    opt.max_iterations = static_cast<size_t>(max_iter);

    poselib::BundleStats stats = poselib::refine_homography(p1, p2, &H, opt);

    std::memcpy(H_out, H.data(), 9 * sizeof(double));
    return static_cast<int>(stats.iterations);
}

// -------------------------------------------------------------------------
// refine_relpose_cam  (CAMERA-aware robust-loss LM bundle — pixel points + cameras)
// -------------------------------------------------------------------------
// Mirrors the RANSAC-Scoring reference: feed PIXEL points + SIMPLE_PINHOLE
// cameras so PoseLib handles calibration internally (one pixel loss width, no per-pair
// scale needed even for differing focals).
// x1, x2:     npts PIXEL points each, 2*npts doubles
// R_in, t_in: seed pose — 9 (col-major) + 3 doubles
// cam1, cam2: [focal, cx, cy] each (SIMPLE_PINHOLE)
// loss_scale: the loss width (Julia `loss_width`) in PIXELS
int poselib_refine_relpose_cam(const double *x1, const double *x2, int npts,
                               const double *R_in, const double *t_in,
                               const double *cam1, const double *cam2,
                               double loss_scale, int max_iter, int loss_type,
                               double *R_out, double *t_out) {
    std::vector<poselib::Point2D> p1(npts), p2(npts);
    for (int i = 0; i < npts; i++) {
        p1[i] = Eigen::Vector2d(x1[2*i], x1[2*i+1]);
        p2[i] = Eigen::Vector2d(x2[2*i], x2[2*i+1]);
    }
    Eigen::Matrix3d R0 = Eigen::Map<const Eigen::Matrix3d>(R_in);
    Eigen::Vector3d t0 = Eigen::Map<const Eigen::Vector3d>(t_in);
    poselib::ImagePair pair;
    pair.pose = poselib::CameraPose(R0, t0);
    pair.camera1 = poselib::Camera("SIMPLE_PINHOLE",
        std::vector<double>{cam1[0], cam1[1], cam1[2]},
        static_cast<int>(2.0 * cam1[1]), static_cast<int>(2.0 * cam1[2]));
    pair.camera2 = poselib::Camera("SIMPLE_PINHOLE",
        std::vector<double>{cam2[0], cam2[1], cam2[2]},
        static_cast<int>(2.0 * cam2[1]), static_cast<int>(2.0 * cam2[2]));

    poselib::BundleOptions opt;
    opt.loss_type = static_cast<poselib::BundleOptions::LossType>(loss_type);
    opt.loss_scale = loss_scale;
    opt.max_iterations = static_cast<size_t>(max_iter);

    poselib::BundleStats stats = poselib::refine_relpose(p1, p2, &pair, opt);

    Eigen::Matrix3d R = pair.pose.R();
    std::memcpy(R_out, R.data(), 9 * sizeof(double));
    std::memcpy(t_out, pair.pose.t.data(), 3 * sizeof(double));
    return static_cast<int>(stats.iterations);
}

// -------------------------------------------------------------------------
// refine_relpose_bearing  (BEARING robust-loss LM bundle — tangent Sampson)
// -------------------------------------------------------------------------
// poselib::refine_relpose(d1, d2, M1, M2, &pose, opt) — bundle.cc:228, the
// FixCameraRelativePoseRefiner. This is the form the ImagePair overload above
// (refine_relpose_cam) reduces to once the intrinsics are fixed: it calls
// camera.unproject_with_jac() and then hands (d, M) straight to this refiner.
// Exposing it directly lets the caller supply bearings from ANY camera model,
// including rays at or beyond 90 degrees, which the z=1 chart cannot name.
//
// The residual is the tangent Sampson
//     r = (d2' E d1) / sqrt(|M2' E d1|^2 + |M1' E' d2|^2)
// whose denominator is exactly |grad C| with respect to the coordinate M
// differentiates AGAINST. So r — and therefore loss_scale — carries THAT
// coordinate's units: M = d(bearing)/d(pixel) gives a residual in PIXELS.
// d1, d2:     npts unit bearings each, 3*npts doubles
// M1, M2:     npts 3x2 matrices each, 6*npts doubles (column-major per point)
// R_in, t_in: seed pose — 9 doubles (column-major 3x3) + 3 doubles
// loss_scale: the loss width (Julia `loss_width`), in M's units
// max_iter:   LM iterations
// R_out, t_out: refined pose — 9 + 3 doubles
// Returns:    number of LM iterations taken (BundleStats.iterations)
int poselib_refine_relpose_bearing(const double *d1, const double *d2,
                                   const double *M1, const double *M2, int npts,
                                   const double *R_in, const double *t_in,
                                   double loss_scale, int max_iter, int loss_type,
                                   double *R_out, double *t_out) {
    std::vector<poselib::Point3D> b1(npts), b2(npts);
    std::vector<Eigen::Matrix<double, 3, 2>> J1(npts), J2(npts);
    for (int i = 0; i < npts; i++) {
        b1[i] = Eigen::Vector3d(d1[3*i], d1[3*i+1], d1[3*i+2]);
        b2[i] = Eigen::Vector3d(d2[3*i], d2[3*i+1], d2[3*i+2]);
        J1[i] = Eigen::Map<const Eigen::Matrix<double, 3, 2>>(M1 + 6*i);
        J2[i] = Eigen::Map<const Eigen::Matrix<double, 3, 2>>(M2 + 6*i);
    }
    Eigen::Matrix3d R0 = Eigen::Map<const Eigen::Matrix3d>(R_in);
    Eigen::Vector3d t0 = Eigen::Map<const Eigen::Vector3d>(t_in);
    poselib::CameraPose pose(R0, t0);

    poselib::BundleOptions opt;
    opt.loss_type = static_cast<poselib::BundleOptions::LossType>(loss_type);
    opt.loss_scale = loss_scale;
    opt.max_iterations = static_cast<size_t>(max_iter);

    poselib::BundleStats stats = poselib::refine_relpose(b1, b2, J1, J2, &pose, opt);

    Eigen::Matrix3d R = pose.R();
    std::memcpy(R_out, R.data(), 9 * sizeof(double));
    std::memcpy(t_out, pose.t.data(), 3 * sizeof(double));
    return static_cast<int>(stats.iterations);
}

// -------------------------------------------------------------------------
// bundle_adjust_cam  (CAMERA-aware absolute-pose bundle — PIXEL points + K)
// -------------------------------------------------------------------------
// poselib::bundle_adjust(x, X, &image, opt) — bundle.cc:105, the Image
// overload, whose AbsolutePoseRefiner forms res = project(camera, R X + t) - x
// with the camera's OWN projection. So x stays in PIXELS and loss_scale is a
// PIXEL loss width. There is deliberately no calibrated (z = 1 chart) sibling: the
// chart has no point for a ray at or beyond 90 degrees, and PoseLib has no
// absolute-pose refiner on bearings — every bundle_adjust overload takes Point2D.
// The camera's parameters are NOT refined: BundleOptions leaves
// refine_focal_length / refine_principal_point / refine_extra_params false, so
// get_param_refinement_idx() returns empty and only the 6-DOF pose moves.
// x:          npts PIXEL points, 2*npts doubles
// X:          npts 3D points, 3*npts doubles
// R_in, t_in: seed pose (world->camera) — 9 doubles (column-major) + 3
// cam:        [focal, cx, cy] (SIMPLE_PINHOLE)
// loss_scale: the loss width (Julia `loss_width`) in PIXELS
// max_iter:   LM iterations
// R_out, t_out: refined pose — 9 + 3 doubles
// Returns:    number of LM iterations taken (BundleStats.iterations)
int poselib_bundle_adjust_cam(const double *x, const double *X, int npts,
                              const double *R_in, const double *t_in,
                              const double *cam,
                              double loss_scale, int max_iter, int loss_type,
                              double *R_out, double *t_out) {
    std::vector<poselib::Point2D> p(npts);
    std::vector<poselib::Point3D> P(npts);
    for (int i = 0; i < npts; i++) {
        p[i] = Eigen::Vector2d(x[2*i], x[2*i+1]);
        P[i] = Eigen::Vector3d(X[3*i], X[3*i+1], X[3*i+2]);
    }
    Eigen::Matrix3d R0 = Eigen::Map<const Eigen::Matrix3d>(R_in);
    Eigen::Vector3d t0 = Eigen::Map<const Eigen::Vector3d>(t_in);
    poselib::Image image;
    image.pose = poselib::CameraPose(R0, t0);
    image.camera = poselib::Camera("SIMPLE_PINHOLE",
        std::vector<double>{cam[0], cam[1], cam[2]},
        static_cast<int>(2.0 * cam[1]), static_cast<int>(2.0 * cam[2]));

    poselib::BundleOptions opt;
    opt.loss_type = static_cast<poselib::BundleOptions::LossType>(loss_type);
    opt.loss_scale = loss_scale;
    opt.max_iterations = static_cast<size_t>(max_iter);

    poselib::BundleStats stats = poselib::bundle_adjust(p, P, &image, opt);

    Eigen::Matrix3d R = image.pose.R();
    std::memcpy(R_out, R.data(), 9 * sizeof(double));
    std::memcpy(t_out, image.pose.t.data(), 3 * sizeof(double));
    return static_cast<int>(stats.iterations);
}

} // extern "C"

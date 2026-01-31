// SPDX-FileCopyrightText: 2024-present Proxima Fusion GmbH
// SPDX-License-Identifier: MIT

// CxxWrap bindings for VMECPP Julia interface

#include "jlcxx/jlcxx.hpp"
#include "jlcxx/stl.hpp"

#include <Eigen/Dense>
#include <filesystem>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "vmecpp/common/magnetic_configuration_lib/magnetic_configuration_lib.h"
#include "vmecpp/common/makegrid_lib/makegrid_lib.h"
#include "vmecpp/common/util/util.h"
#include "vmecpp/common/vmec_indata/vmec_indata.h"
#include "vmecpp/vmec/output_quantities/output_quantities.h"
#include "vmecpp/vmec/vmec/vmec.h"

using Eigen::VectorXd;
using Eigen::VectorXi;
using Eigen::MatrixXd;
using vmecpp::RowMatrixXd;
using vmecpp::VmecINDATA;

// Eigen type mappings for CxxWrap
namespace jlcxx {
  template<> struct IsMirroredType<Eigen::VectorXd> : std::false_type {};
  template<> struct IsMirroredType<Eigen::VectorXi> : std::false_type {};
  template<> struct IsMirroredType<Eigen::MatrixXd> : std::false_type {};
  template<> struct IsMirroredType<vmecpp::RowMatrixXd> : std::false_type {};
}  // namespace jlcxx

namespace {

// Helper function to throw on absl::Status errors
template <typename T>
T& GetValueOrThrow(absl::StatusOr<T>& s) {
  if (!s.ok()) {
    jl_error(s.status().message().data());
  }
  return s.value();
}

// Conversion helpers for Julia <-> Eigen
VectorXi MakeVectorXi(jlcxx::ArrayRef<int> arr) {
  return Eigen::Map<const VectorXi>(arr.data(), arr.size());
}

VectorXd MakeVectorXd(jlcxx::ArrayRef<double> arr) {
  return Eigen::Map<const VectorXd>(arr.data(), arr.size());
}

RowMatrixXd MakeRowMatrixXd(jlcxx::ArrayRef<double> arr, int rows, int cols) {
  return Eigen::Map<const RowMatrixXd>(arr.data(), rows, cols);
}

// Helper to create HotRestartState
vmecpp::HotRestartState MakeHotRestartState(
    vmecpp::WOutFileContents wout, const VmecINDATA& indata) {
  return vmecpp::HotRestartState(std::move(wout), indata);
}

// Basic run() without hot restart
vmecpp::OutputQuantities RunVmecBasic(
    const VmecINDATA& indata,
    bool verbose) {
  auto ret = vmecpp::run(indata, std::nullopt, std::nullopt, verbose);
  return GetValueOrThrow(ret);
}

// run() with max_threads
vmecpp::OutputQuantities RunVmecWithThreads(
    const VmecINDATA& indata,
    int max_threads,
    bool verbose) {
  auto ret = vmecpp::run(indata, std::nullopt, max_threads, verbose);
  return GetValueOrThrow(ret);
}

// run() with hot restart
vmecpp::OutputQuantities RunVmecWithRestart(
    const VmecINDATA& indata,
    const vmecpp::HotRestartState& initial_state,
    bool verbose) {
  auto ret = vmecpp::run(indata, initial_state, std::nullopt, verbose);
  return GetValueOrThrow(ret);
}

// run() with hot restart and threads
vmecpp::OutputQuantities RunVmecWithRestartAndThreads(
    const VmecINDATA& indata,
    const vmecpp::HotRestartState& initial_state,
    int max_threads,
    bool verbose) {
  auto ret = vmecpp::run(indata, initial_state, max_threads, verbose);
  return GetValueOrThrow(ret);
}

// Free boundary - basic
vmecpp::OutputQuantities RunVmecFreeBoundaryBasic(
    const VmecINDATA& indata,
    const makegrid::MagneticFieldResponseTable& magnetic_response_table,
    bool verbose) {
  auto ret = vmecpp::run(indata, magnetic_response_table,
                         std::nullopt, std::nullopt, verbose);
  return GetValueOrThrow(ret);
}

// Free boundary with threads
vmecpp::OutputQuantities RunVmecFreeBoundaryWithThreads(
    const VmecINDATA& indata,
    const makegrid::MagneticFieldResponseTable& magnetic_response_table,
    int max_threads,
    bool verbose) {
  auto ret = vmecpp::run(indata, magnetic_response_table,
                         std::nullopt, max_threads, verbose);
  return GetValueOrThrow(ret);
}

// Free boundary with hot restart
vmecpp::OutputQuantities RunVmecFreeBoundaryWithRestart(
    const VmecINDATA& indata,
    const makegrid::MagneticFieldResponseTable& magnetic_response_table,
    const vmecpp::HotRestartState& initial_state,
    bool verbose) {
  auto ret = vmecpp::run(indata, magnetic_response_table,
                         initial_state, std::nullopt, verbose);
  return GetValueOrThrow(ret);
}

// Free boundary with hot restart and threads
vmecpp::OutputQuantities RunVmecFreeBoundaryWithRestartAndThreads(
    const VmecINDATA& indata,
    const makegrid::MagneticFieldResponseTable& magnetic_response_table,
    const vmecpp::HotRestartState& initial_state,
    int max_threads,
    bool verbose) {
  auto ret = vmecpp::run(indata, magnetic_response_table,
                         initial_state, max_threads, verbose);
  return GetValueOrThrow(ret);
}

} // anonymous namespace

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  // ============================================================================
  // Eigen types (must come first for type system)
  // ============================================================================
  mod.add_type<Eigen::VectorXd>("VectorXd")
    .method("size", &Eigen::VectorXd::size)
    .method("data", [](Eigen::VectorXd& v) {
      return jlcxx::ArrayRef<double>(v.data(), v.size());
    });

  mod.add_type<Eigen::VectorXi>("VectorXi")
    .method("size", &Eigen::VectorXi::size)
    .method("data", [](Eigen::VectorXi& v) {
      return jlcxx::ArrayRef<int>(v.data(), v.size());
    });

  mod.add_type<Eigen::MatrixXd>("MatrixXd")
    .method("rows", &Eigen::MatrixXd::rows)
    .method("cols", &Eigen::MatrixXd::cols)
    .method("data", [](Eigen::MatrixXd& m) {
      return jlcxx::ArrayRef<double>(m.data(), m.size());
    });

  mod.add_type<RowMatrixXd>("RowMatrixXd")
    .method("rows", &RowMatrixXd::rows)
    .method("cols", &RowMatrixXd::cols)
    .method("data", [](RowMatrixXd& m) {
      return jlcxx::ArrayRef<double>(m.data(), m.size());
    });

  // Conversion functions for Julia arrays -> Eigen types
  mod.method("make_vector_xi", &MakeVectorXi);
  mod.method("make_vector_xd", &MakeVectorXd);
  mod.method("make_row_matrix_xd", &MakeRowMatrixXd);

  mod.add_type<std::filesystem::path>("FilesystemPath")
    .constructor<const std::string&>();

  // ============================================================================
  // FreeBoundaryMethod enum
  // ============================================================================
  mod.add_bits<vmecpp::FreeBoundaryMethod>("FreeBoundaryMethod", jlcxx::julia_type("CppEnum"));
  mod.set_const("NESTOR", vmecpp::FreeBoundaryMethod::NESTOR);
  mod.set_const("BIEST", vmecpp::FreeBoundaryMethod::BIEST);

  // ============================================================================
  // VmecINDATA - Input configuration
  // ============================================================================
  auto vmec_indata = mod.add_type<VmecINDATA>("VmecINDATA")
    .constructor<>();

  // Static methods for loading from file/json
  mod.method("vmec_indata_from_file", [](const std::string& filename) -> VmecINDATA {
    return VmecINDATA::FromFile(std::filesystem::path(filename));
  });
  mod.method("vmec_indata_from_json", [](const std::string& json_str) -> VmecINDATA {
    auto result = VmecINDATA::FromJson(json_str);
    return GetValueOrThrow(result);
  });
  mod.method("vmec_indata_to_json", [](const VmecINDATA& indata) -> std::string {
    return indata.ToJsonOrException();
  });

  // Numerical resolution and symmetry
  vmec_indata.method("lasym", [](VmecINDATA& w) { return w.lasym; });
  vmec_indata.method("set_lasym!", [](VmecINDATA& w, bool v) { w.lasym = v; });
  vmec_indata.method("nfp", [](VmecINDATA& w) { return w.nfp; });
  vmec_indata.method("set_nfp!", [](VmecINDATA& w, int v) { w.nfp = v; });
  vmec_indata.method("mpol", [](VmecINDATA& w) { return w.mpol; });
  vmec_indata.method("ntor", [](VmecINDATA& w) { return w.ntor; });
  vmec_indata.method("set_mpol_ntor!", [](VmecINDATA& w, int mpol, int ntor) { w.SetMpolNtor(mpol, ntor); });
  vmec_indata.method("ntheta", [](VmecINDATA& w) { return w.ntheta; });
  vmec_indata.method("set_ntheta!", [](VmecINDATA& w, int v) { w.ntheta = v; });
  vmec_indata.method("nzeta", [](VmecINDATA& w) { return w.nzeta; });
  vmec_indata.method("set_nzeta!", [](VmecINDATA& w, int v) { w.nzeta = v; });

  // Multigrid arrays (Eigen vectors - mutable)
  vmec_indata.method("ns_array", [](VmecINDATA& w) -> VectorXi& { return w.ns_array; });
  vmec_indata.method("set_ns_array!", [](VmecINDATA& w, const VectorXi& v) { w.ns_array = v; });
  vmec_indata.method("ftol_array", [](VmecINDATA& w) -> VectorXd& { return w.ftol_array; });
  vmec_indata.method("set_ftol_array!", [](VmecINDATA& w, const VectorXd& v) { w.ftol_array = v; });
  vmec_indata.method("niter_array", [](VmecINDATA& w) -> VectorXi& { return w.niter_array; });
  vmec_indata.method("set_niter_array!", [](VmecINDATA& w, const VectorXi& v) { w.niter_array = v; });

  // Physics parameters
  vmec_indata.method("phiedge", [](VmecINDATA& w) { return w.phiedge; });
  vmec_indata.method("set_phiedge!", [](VmecINDATA& w, double v) { w.phiedge = v; });
  vmec_indata.method("ncurr", [](VmecINDATA& w) { return w.ncurr; });
  vmec_indata.method("set_ncurr!", [](VmecINDATA& w, int v) { w.ncurr = v; });
  vmec_indata.method("pmass_type", [](VmecINDATA& w) { return w.pmass_type; });
  vmec_indata.method("set_pmass_type!", [](VmecINDATA& w, const std::string& v) { w.pmass_type = v; });

  // Profile arrays
  vmec_indata.method("am", [](VmecINDATA& w) -> VectorXd& { return w.am; });
  vmec_indata.method("set_am!", [](VmecINDATA& w, const VectorXd& v) { w.am = v; });
  vmec_indata.method("am_aux_s", [](VmecINDATA& w) -> VectorXd& { return w.am_aux_s; });
  vmec_indata.method("set_am_aux_s!", [](VmecINDATA& w, const VectorXd& v) { w.am_aux_s = v; });
  vmec_indata.method("am_aux_f", [](VmecINDATA& w) -> VectorXd& { return w.am_aux_f; });
  vmec_indata.method("set_am_aux_f!", [](VmecINDATA& w, const VectorXd& v) { w.am_aux_f = v; });

  vmec_indata.method("pres_scale", [](VmecINDATA& w) { return w.pres_scale; });
  vmec_indata.method("set_pres_scale!", [](VmecINDATA& w, double v) { w.pres_scale = v; });
  vmec_indata.method("gamma", [](VmecINDATA& w) { return w.gamma; });
  vmec_indata.method("set_gamma!", [](VmecINDATA& w, double v) { w.gamma = v; });
  vmec_indata.method("spres_ped", [](VmecINDATA& w) { return w.spres_ped; });
  vmec_indata.method("set_spres_ped!", [](VmecINDATA& w, double v) { w.spres_ped = v; });

  // Iota profile
  vmec_indata.method("piota_type", [](VmecINDATA& w) { return w.piota_type; });
  vmec_indata.method("set_piota_type!", [](VmecINDATA& w, const std::string& v) { w.piota_type = v; });
  vmec_indata.method("ai", [](VmecINDATA& w) -> VectorXd& { return w.ai; });
  vmec_indata.method("set_ai!", [](VmecINDATA& w, const VectorXd& v) { w.ai = v; });
  vmec_indata.method("ai_aux_s", [](VmecINDATA& w) -> VectorXd& { return w.ai_aux_s; });
  vmec_indata.method("set_ai_aux_s!", [](VmecINDATA& w, const VectorXd& v) { w.ai_aux_s = v; });
  vmec_indata.method("ai_aux_f", [](VmecINDATA& w) -> VectorXd& { return w.ai_aux_f; });
  vmec_indata.method("set_ai_aux_f!", [](VmecINDATA& w, const VectorXd& v) { w.ai_aux_f = v; });

  // Current profile
  vmec_indata.method("pcurr_type", [](VmecINDATA& w) { return w.pcurr_type; });
  vmec_indata.method("set_pcurr_type!", [](VmecINDATA& w, const std::string& v) { w.pcurr_type = v; });
  vmec_indata.method("ac", [](VmecINDATA& w) -> VectorXd& { return w.ac; });
  vmec_indata.method("set_ac!", [](VmecINDATA& w, const VectorXd& v) { w.ac = v; });
  vmec_indata.method("ac_aux_s", [](VmecINDATA& w) -> VectorXd& { return w.ac_aux_s; });
  vmec_indata.method("set_ac_aux_s!", [](VmecINDATA& w, const VectorXd& v) { w.ac_aux_s = v; });
  vmec_indata.method("ac_aux_f", [](VmecINDATA& w) -> VectorXd& { return w.ac_aux_f; });
  vmec_indata.method("set_ac_aux_f!", [](VmecINDATA& w, const VectorXd& v) { w.ac_aux_f = v; });
  vmec_indata.method("curtor", [](VmecINDATA& w) { return w.curtor; });
  vmec_indata.method("set_curtor!", [](VmecINDATA& w, double v) { w.curtor = v; });
  vmec_indata.method("bloat", [](VmecINDATA& w) { return w.bloat; });
  vmec_indata.method("set_bloat!", [](VmecINDATA& w, double v) { w.bloat = v; });

  // Free boundary parameters
  vmec_indata.method("lfreeb", [](VmecINDATA& w) { return w.lfreeb; });
  vmec_indata.method("set_lfreeb!", [](VmecINDATA& w, bool v) { w.lfreeb = v; });
  vmec_indata.method("mgrid_file", [](VmecINDATA& w) { return w.mgrid_file; });
  vmec_indata.method("set_mgrid_file!", [](VmecINDATA& w, const std::string& v) { w.mgrid_file = v; });
  vmec_indata.method("extcur", [](VmecINDATA& w) -> VectorXd& { return w.extcur; });
  vmec_indata.method("set_extcur!", [](VmecINDATA& w, const VectorXd& v) { w.extcur = v; });
  vmec_indata.method("nvacskip", [](VmecINDATA& w) { return w.nvacskip; });
  vmec_indata.method("set_nvacskip!", [](VmecINDATA& w, int v) { w.nvacskip = v; });
  vmec_indata.method("free_boundary_method", [](VmecINDATA& w) { return w.free_boundary_method; });
  vmec_indata.method("set_free_boundary_method!", [](VmecINDATA& w, vmecpp::FreeBoundaryMethod v) {
    w.free_boundary_method = v;
  });

  // Tweaking parameters
  vmec_indata.method("nstep", [](VmecINDATA& w) { return w.nstep; });
  vmec_indata.method("set_nstep!", [](VmecINDATA& w, int v) { w.nstep = v; });
  vmec_indata.method("aphi", [](VmecINDATA& w) -> VectorXd& { return w.aphi; });
  vmec_indata.method("set_aphi!", [](VmecINDATA& w, const VectorXd& v) { w.aphi = v; });
  vmec_indata.method("delt", [](VmecINDATA& w) { return w.delt; });
  vmec_indata.method("set_delt!", [](VmecINDATA& w, double v) { w.delt = v; });
  vmec_indata.method("tcon0", [](VmecINDATA& w) { return w.tcon0; });
  vmec_indata.method("set_tcon0!", [](VmecINDATA& w, double v) { w.tcon0 = v; });
  vmec_indata.method("lforbal", [](VmecINDATA& w) { return w.lforbal; });
  vmec_indata.method("set_lforbal!", [](VmecINDATA& w, bool v) { w.lforbal = v; });
  vmec_indata.method("return_outputs_even_if_not_converged", [](VmecINDATA& w) {
    return w.return_outputs_even_if_not_converged;
  });
  vmec_indata.method("set_return_outputs_even_if_not_converged!", [](VmecINDATA& w, bool v) {
    w.return_outputs_even_if_not_converged = v;
  });

  // Boundary shape (Fourier coefficients)
  vmec_indata.method("rbc", [](VmecINDATA& w) -> vmecpp::RowMatrixXd& { return w.rbc; });
  vmec_indata.method("set_rbc!", [](VmecINDATA& w, const RowMatrixXd& v) { w.rbc = v; });
  vmec_indata.method("zbs", [](VmecINDATA& w) -> vmecpp::RowMatrixXd& { return w.zbs; });
  vmec_indata.method("set_zbs!", [](VmecINDATA& w, const RowMatrixXd& v) { w.zbs = v; });

  // Axis shape
  vmec_indata.method("raxis_c", [](VmecINDATA& w) -> VectorXd& { return w.raxis_c; });
  vmec_indata.method("set_raxis_c!", [](VmecINDATA& w, const VectorXd& v) { w.raxis_c = v; });
  vmec_indata.method("zaxis_s", [](VmecINDATA& w) -> VectorXd& { return w.zaxis_s; });
  vmec_indata.method("set_zaxis_s!", [](VmecINDATA& w, const VectorXd& v) { w.zaxis_s = v; });

  // ============================================================================
  // Output structures
  // ============================================================================

  // WOutFileContents - primary output
  auto wout = mod.add_type<vmecpp::WOutFileContents>("WOutFileContents");

  // Scalar outputs - floats
  wout.method("aspect", [](const vmecpp::WOutFileContents& w) { return w.aspect; });
  wout.method("betatot", [](const vmecpp::WOutFileContents& w) { return w.betatot; });
  wout.method("betapol", [](const vmecpp::WOutFileContents& w) { return w.betapol; });
  wout.method("betator", [](const vmecpp::WOutFileContents& w) { return w.betator; });
  wout.method("b0", [](const vmecpp::WOutFileContents& w) { return w.b0; });
  wout.method("volume_p", [](const vmecpp::WOutFileContents& w) { return w.volume_p; });
  wout.method("ctor", [](const vmecpp::WOutFileContents& w) { return w.ctor; });
  wout.method("rbtor", [](const vmecpp::WOutFileContents& w) { return w.rbtor; });
  wout.method("rbtor0", [](const vmecpp::WOutFileContents& w) { return w.rbtor0; });
  wout.method("fsqr", [](const vmecpp::WOutFileContents& w) { return w.fsqr; });
  wout.method("ftolv", [](const vmecpp::WOutFileContents& w) { return w.ftolv; });
  wout.method("Aminor_p", [](const vmecpp::WOutFileContents& w) { return w.Aminor_p; });
  wout.method("Rmajor_p", [](const vmecpp::WOutFileContents& w) { return w.Rmajor_p; });

  // Scalar outputs - integers
  wout.method("ns", [](const vmecpp::WOutFileContents& w) { return w.ns; });
  wout.method("mpol", [](const vmecpp::WOutFileContents& w) { return w.mpol; });
  wout.method("ntor", [](const vmecpp::WOutFileContents& w) { return w.ntor; });
  wout.method("nfp", [](const vmecpp::WOutFileContents& w) { return w.nfp; });
  wout.method("mnmax", [](const vmecpp::WOutFileContents& w) { return w.mnmax; });
  wout.method("niter", [](const vmecpp::WOutFileContents& w) { return w.maximum_iterations; });
  wout.method("itfsq", [](const vmecpp::WOutFileContents& w) { return w.itfsq; });

  // Scalar outputs - booleans
  wout.method("lfreeb", [](const vmecpp::WOutFileContents& w) { return w.lfreeb; });
  wout.method("lasym", [](const vmecpp::WOutFileContents& w) { return w.lasym; });

  // Profile arrays - return by value (CxxWrap will handle conversion)
  wout.method("iota_full", [](const vmecpp::WOutFileContents& w) { return w.iota_full; });
  wout.method("pressure_full", [](const vmecpp::WOutFileContents& w) { return w.pressure_full; });
  wout.method("toroidal_flux", [](const vmecpp::WOutFileContents& w) { return w.toroidal_flux; });
  wout.method("iota_half", [](const vmecpp::WOutFileContents& w) { return w.iota_half; });

  // Convergence arrays
  wout.method("fsqt", [](const vmecpp::WOutFileContents& w) { return w.fsqt; });
  wout.method("force_residual_r", [](const vmecpp::WOutFileContents& w) { return w.force_residual_r; });
  wout.method("force_residual_z", [](const vmecpp::WOutFileContents& w) { return w.force_residual_z; });
  wout.method("force_residual_lambda", [](const vmecpp::WOutFileContents& w) { return w.force_residual_lambda; });
  wout.method("delbsq", [](const vmecpp::WOutFileContents& w) { return w.delbsq; });

  // Mode number arrays
  wout.method("xm", [](const vmecpp::WOutFileContents& w) { return w.xm; });
  wout.method("xn", [](const vmecpp::WOutFileContents& w) { return w.xn; });
  wout.method("xm_nyq", [](const vmecpp::WOutFileContents& w) { return w.xm_nyq; });
  wout.method("xn_nyq", [](const vmecpp::WOutFileContents& w) { return w.xn_nyq; });

  // Axis coefficients
  wout.method("raxis_c", [](const vmecpp::WOutFileContents& w) { return w.raxis_c; });
  wout.method("zaxis_s", [](const vmecpp::WOutFileContents& w) { return w.zaxis_s; });

  // Fourier mode arrays - return by value (CxxWrap will handle conversion)
  wout.method("rmnc", [](const vmecpp::WOutFileContents& w) { return w.rmnc; });
  wout.method("zmns", [](const vmecpp::WOutFileContents& w) { return w.zmns; });
  wout.method("bmnc", [](const vmecpp::WOutFileContents& w) { return w.bmnc; });
  wout.method("lmns_full", [](const vmecpp::WOutFileContents& w) { return w.lmns_full; });

  // Asymmetric Fourier mode arrays (only populated when lasym=true)
  wout.method("rmns", [](const vmecpp::WOutFileContents& w) { return w.rmns; });
  wout.method("zmnc", [](const vmecpp::WOutFileContents& w) { return w.zmnc; });
  wout.method("bmns", [](const vmecpp::WOutFileContents& w) { return w.bmns; });
  wout.method("lmnc", [](const vmecpp::WOutFileContents& w) { return w.lmnc; });

  // Covariant B components (needed for Boozer transformation)
  wout.method("bsubumnc", [](const vmecpp::WOutFileContents& w) { return w.bsubumnc; });
  wout.method("bsubvmnc", [](const vmecpp::WOutFileContents& w) { return w.bsubvmnc; });
  wout.method("bsubumns", [](const vmecpp::WOutFileContents& w) { return w.bsubumns; });
  wout.method("bsubvmns", [](const vmecpp::WOutFileContents& w) { return w.bsubvmns; });

  // Threed1GeometricAndMagneticQuantities - geometric quantities
  mod.add_type<vmecpp::Threed1GeometricAndMagneticQuantities>("Threed1GeometricAndMagneticQuantities")
    .method("surf_area_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.surf_area_p; })
    .method("cross_area_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.cross_area_p; })
    .method("volume_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.volume_p; })
    .method("Rmajor_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.Rmajor_p; })
    .method("Aminor_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.Aminor_p; })
    .method("aspect", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.aspect; })
    .method("circum_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.circum_p; })
    .method("kappa_p", [](const vmecpp::Threed1GeometricAndMagneticQuantities& g) { return g.kappa_p; });

  // JxBOutFileContents - force diagnostics
  mod.add_type<vmecpp::JxBOutFileContents>("JxBOutFileContents")
    .method("bdotk", [](const vmecpp::JxBOutFileContents& j) { return j.bdotk; })
    .method("avforce", [](const vmecpp::JxBOutFileContents& j) { return j.avforce; });

  // MercierFileContents - stability analysis
  mod.add_type<vmecpp::MercierFileContents>("MercierFileContents")
    .method("s", [](const vmecpp::MercierFileContents& m) { return m.s; })
    .method("iota", [](const vmecpp::MercierFileContents& m) { return m.iota; });

  // OutputQuantities - main result container
  mod.add_type<vmecpp::OutputQuantities>("OutputQuantities")
    .method("wout", [](vmecpp::OutputQuantities& o) -> vmecpp::WOutFileContents& { return o.wout; })
    .method("jxbout", [](vmecpp::OutputQuantities& o) -> vmecpp::JxBOutFileContents& { return o.jxbout; })
    .method("mercier", [](vmecpp::OutputQuantities& o) -> vmecpp::MercierFileContents& { return o.mercier; })
    .method("threed1_geometric_magnetic", [](vmecpp::OutputQuantities& o) -> vmecpp::Threed1GeometricAndMagneticQuantities& {
      return o.threed1_geometric_magnetic;
    });

  // HotRestartState
  mod.add_type<vmecpp::HotRestartState>("HotRestartState");
  mod.method("make_hot_restart_state", &MakeHotRestartState);

  // ============================================================================
  // Free boundary support
  // ============================================================================

  // MakegridParameters with file loading
  mod.add_type<makegrid::MakegridParameters>("MakegridParameters")
    .constructor<>();

  // Add a method to load from file (since CxxWrap constructors can't use lambdas easily)
  mod.method("load_makegrid_parameters", [](const std::string& filename) {
    auto result = makegrid::ImportMakegridParametersFromFile(std::filesystem::path(filename));
    return GetValueOrThrow(result);
  });

  // MagneticFieldResponseTable with constructor from coils file
  mod.add_type<makegrid::MagneticFieldResponseTable>("MagneticFieldResponseTable")
    .constructor<>();

  // Add a method to create from coils file and parameters
  mod.method("create_magnetic_response_table", [](const std::string& coils_file, const makegrid::MakegridParameters& params) {
    auto config_result = magnetics::ImportMagneticConfigurationFromCoilsFile(std::filesystem::path(coils_file));
    if (!config_result.ok()) {
      jl_error(config_result.status().message().data());
    }
    auto table_result = makegrid::ComputeMagneticFieldResponseTable(params, config_result.value());
    return GetValueOrThrow(table_result);
  });

  // Add field accessors and modifiers for MagneticFieldResponseTable
  // These provide in-place scalar multiplication without broadcasting issues
  mod.method("scale_b_r!", [](makegrid::MagneticFieldResponseTable& table, double factor) {
    table.b_r *= factor;
  });
  mod.method("scale_b_p!", [](makegrid::MagneticFieldResponseTable& table, double factor) {
    table.b_p *= factor;
  });
  mod.method("scale_b_z!", [](makegrid::MagneticFieldResponseTable& table, double factor) {
    table.b_z *= factor;
  });

  // ============================================================================
  // Main run() functions
  // ============================================================================

  // Fixed boundary modes
  mod.method("run_basic", &RunVmecBasic);
  mod.method("run_with_threads", &RunVmecWithThreads);
  mod.method("run_with_restart", &RunVmecWithRestart);
  mod.method("run_with_restart_and_threads", &RunVmecWithRestartAndThreads);

  // Free boundary modes
  mod.method("run_free_boundary_basic", &RunVmecFreeBoundaryBasic);
  mod.method("run_free_boundary_with_threads", &RunVmecFreeBoundaryWithThreads);
  mod.method("run_free_boundary_with_restart", &RunVmecFreeBoundaryWithRestart);
  mod.method("run_free_boundary_with_restart_and_threads", &RunVmecFreeBoundaryWithRestartAndThreads);
}

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "ORTools"
version = v"9.15.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/google/or-tools.git",
        "551ad10d94835c99e5e1e684500d3db398c0e345"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# Use CMake_jll instead of the base image CMake
apk del cmake

cd $WORKSPACE/srcdir/or-tools*
mkdir build
cmake --version

# Ensure host tools are built with host toolchain when cross-compiling
export AR=$HOSTAR
export AS=$HOSTAS
export CC=$HOSTCC
export CXX=$HOSTCXX
export DSYMUTIL=$HOSTDSYMUTIL
export FC=$HOSTFC
export includedir=$host_includedir
export libdir=$host_libdir
export LIPO=$HOSTLIPO
export LD=$HOSTLD
export NM=$HOSTNM
export OBJCOPY=$HOSTOBJCOPY
export OBJDUMP=$HOSTOBJDUMP
export RANLIB=$HOSTRANLIB
export READELF=$HOSTREADELF
export STRIP=$HOSTSTRIP

if [[ "$target" == *mingw* ]]; then
    # MinGW doesn't expose M_PI unless _USE_MATH_DEFINES is set
    # See: https://learn.microsoft.com/en-us/cpp/c-runtime-library/math-constants?view=msvc-170
    export CXXFLAGS="${CXXFLAGS} -D_USE_MATH_DEFINES"
fi

cmake -S. -Bbuild \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_DEPS:BOOL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING:BOOL=OFF \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_SAMPLES:BOOL=OFF \
    -DUSE_SCIP:BOOL=OFF \
    -DUSE_HIGHS:BOOL=OFF \
    -DUSE_COINOR:BOOL=OFF \
    -DUSE_GLPK:BOOL=OFF

# Remove target-specific -march flags added by Abseil
# See: Yggdrasil/AGENTS.md (Unsupported Build Flags section)
if [ -d "build/_deps/abseil-cpp-src" ]; then
    echo "Patching Abseil CMake files to remove -march flags..."
    find build/_deps/abseil-cpp-src -name "*.cmake" -type f -exec sed -i 's/-march[^ ]*//g' {} + 2>/dev/null || true
    find build/_deps/abseil-cpp-src -name "CMakeLists.txt" -type f -exec sed -i 's/-march[^ ]*//g' {} + 2>/dev/null || true
    find build/_deps/abseil-cpp-build -name "*.cmake" -type f -exec sed -i 's/-march[^ ]*//g' {} + 2>/dev/null || true

    # armv6l cross-compilation: disable randen_hwaes (ARM AES instructions not available).
    # See: https://github.com/abseil/abseil-cpp/issues/662
    if [[ "$target" == armv6l* ]]; then
        if [ -f "build/_deps/abseil-cpp-src/CMakeLists.txt" ]; then
            sed -i 's/ABSL_RANDOM_HWAES_ARM32_FLAGS//g' build/_deps/abseil-cpp-src/CMakeLists.txt || true
        fi
    fi
fi

cmake --build build
cmake --build build --target install

# Install upstream .proto definitions
install -Dvm 644 ortools/bop/bop_parameters.proto ${prefix}/include/ortools/bop/bop_parameters.proto
install -Dvm 644 ortools/constraint_solver/assignment.proto ${prefix}/include/ortools/constraint_solver/assignment.proto
install -Dvm 644 ortools/constraint_solver/demon_profiler.proto ${prefix}/include/ortools/constraint_solver/demon_profiler.proto
install -Dvm 644 ortools/constraint_solver/routing_enums.proto ${prefix}/include/ortools/constraint_solver/routing_enums.proto
install -Dvm 644 ortools/constraint_solver/routing_heuristic_parameters.proto ${prefix}/include/ortools/constraint_solver/routing_heuristic_parameters.proto
install -Dvm 644 ortools/constraint_solver/routing_ils.proto ${prefix}/include/ortools/constraint_solver/routing_ils.proto
install -Dvm 644 ortools/constraint_solver/routing_parameters.proto ${prefix}/include/ortools/constraint_solver/routing_parameters.proto
install -Dvm 644 ortools/constraint_solver/search_limit.proto ${prefix}/include/ortools/constraint_solver/search_limit.proto
install -Dvm 644 ortools/constraint_solver/search_stats.proto ${prefix}/include/ortools/constraint_solver/search_stats.proto
install -Dvm 644 ortools/constraint_solver/solver_parameters.proto ${prefix}/include/ortools/constraint_solver/solver_parameters.proto
install -Dvm 644 ortools/glop/parameters.proto ${prefix}/include/ortools/glop/parameters.proto
install -Dvm 644 ortools/graph/flow_problem.proto ${prefix}/include/ortools/graph/flow_problem.proto
install -Dvm 644 ortools/linear_solver/linear_solver.proto ${prefix}/include/ortools/linear_solver/linear_solver.proto
install -Dvm 644 ortools/math_opt/callback.proto ${prefix}/include/ortools/math_opt/callback.proto
install -Dvm 644 ortools/math_opt/infeasible_subsystem.proto ${prefix}/include/ortools/math_opt/infeasible_subsystem.proto
install -Dvm 644 ortools/math_opt/model.proto ${prefix}/include/ortools/math_opt/model.proto
install -Dvm 644 ortools/math_opt/model_parameters.proto ${prefix}/include/ortools/math_opt/model_parameters.proto
install -Dvm 644 ortools/math_opt/model_update.proto ${prefix}/include/ortools/math_opt/model_update.proto
install -Dvm 644 ortools/math_opt/parameters.proto ${prefix}/include/ortools/math_opt/parameters.proto
install -Dvm 644 ortools/math_opt/result.proto ${prefix}/include/ortools/math_opt/result.proto
install -Dvm 644 ortools/math_opt/solution.proto ${prefix}/include/ortools/math_opt/solution.proto
install -Dvm 644 ortools/math_opt/solvers/glpk.proto ${prefix}/include/ortools/math_opt/solvers/glpk.proto
install -Dvm 644 ortools/math_opt/solvers/gscip/gscip.proto ${prefix}/include/ortools/math_opt/solvers/gscip/gscip.proto
install -Dvm 644 ortools/math_opt/solvers/gurobi.proto ${prefix}/include/ortools/math_opt/solvers/gurobi.proto
install -Dvm 644 ortools/math_opt/solvers/highs.proto ${prefix}/include/ortools/math_opt/solvers/highs.proto
install -Dvm 644 ortools/math_opt/solvers/osqp.proto ${prefix}/include/ortools/math_opt/solvers/osqp.proto
install -Dvm 644 ortools/math_opt/solvers/xpress.proto ${prefix}/include/ortools/math_opt/solvers/xpress.proto
install -Dvm 644 ortools/math_opt/sparse_containers.proto ${prefix}/include/ortools/math_opt/sparse_containers.proto
install -Dvm 644 ortools/packing/multiple_dimensions_bin_packing.proto ${prefix}/include/ortools/packing/multiple_dimensions_bin_packing.proto
install -Dvm 644 ortools/packing/vector_bin_packing.proto ${prefix}/include/ortools/packing/vbp/vector_bin_packing.proto
install -Dvm 644 ortools/pdlp/solve_log.proto ${prefix}/include/ortools/pdlp/solve_log.proto
install -Dvm 644 ortools/pdlp/solvers.proto ${prefix}/include/ortools/pdlp/solvers.proto
install -Dvm 644 ortools/sat/boolean_problem.proto ${prefix}/include/ortools/sat/boolean_problem.proto
install -Dvm 644 ortools/sat/cp_model.proto ${prefix}/include/ortools/sat/cp_model.proto
install -Dvm 644 ortools/sat/lrat.proto ${prefix}/include/ortools/sat/lrat.proto
install -Dvm 644 ortools/sat/sat_parameters.proto ${prefix}/include/ortools/sat/sat_parameters.proto
install -Dvm 644 ortools/scheduling/course_scheduling.proto ${prefix}/include/ortools/scheduling/course_scheduling.proto
install -Dvm 644 ortools/scheduling/jobshop_scheduling.proto ${prefix}/include/ortools/scheduling/jobshop_scheduling.proto
install -Dvm 644 ortools/scheduling/rcpsp.proto ${prefix}/include/ortools/scheduling/rcpsp/rcpsp.proto
install -Dvm 644 ortools/util/optional_boolean.proto ${prefix}/include/ortools/util/optional_boolean.proto
"""

# These are the platforms we will build for by default
platforms = supported_platforms()
# Disable RISC-V due to protoc segfault during .proto generation
platforms = filter(p -> arch(p) != "riscv64", platforms)
# Disable i686 Windows due to BZip2 linking issue
platforms = filter(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libortools", :libortools),
    LibraryProduct("libortools_flatzinc", :libortools_flatzinc),

    ExecutableProduct("fzn-cp-sat", :fzncpsat),
    ExecutableProduct("sat_runner", :sat_runner),
    ExecutableProduct("solve", :solve),

    # .proto files shipped by OR-Tools (sorted by path)
    FileProduct("include/ortools/bop/bop_parameters.proto", :proto_bop_parameters),
    FileProduct("include/ortools/constraint_solver/assignment.proto", :proto_constraint_solver_assignment),
    FileProduct("include/ortools/constraint_solver/demon_profiler.proto", :proto_constraint_solver_demon_profiler),
    FileProduct("include/ortools/constraint_solver/routing_enums.proto", :proto_constraint_solver_routing_enums),
    FileProduct("include/ortools/constraint_solver/routing_heuristic_parameters.proto", :proto_constraint_solver_routing_heuristic_parameters),
    FileProduct("include/ortools/constraint_solver/routing_ils.proto", :proto_constraint_solver_routing_ils),
    FileProduct("include/ortools/constraint_solver/routing_parameters.proto", :proto_constraint_solver_routing_parameters),
    FileProduct("include/ortools/constraint_solver/search_limit.proto", :proto_constraint_solver_search_limit),
    FileProduct("include/ortools/constraint_solver/search_stats.proto", :proto_constraint_solver_search_stats),
    FileProduct("include/ortools/constraint_solver/solver_parameters.proto", :proto_constraint_solver_solver_parameters),
    FileProduct("include/ortools/glop/parameters.proto", :ortools_glop_parameters),
    FileProduct("include/ortools/graph/flow_problem.proto", :ortools_graph_flow_problem),
    FileProduct("include/ortools/linear_solver/linear_solver.proto", :proto_linear_solver),
    FileProduct("include/ortools/math_opt/callback.proto", :proto_math_opt_callback),
    FileProduct("include/ortools/math_opt/infeasible_subsystem.proto", :proto_math_opt_infeasible_subsystem),
    FileProduct("include/ortools/math_opt/model.proto", :proto_math_opt_model),
    FileProduct("include/ortools/math_opt/model_parameters.proto", :proto_math_opt_model_parameters),
    FileProduct("include/ortools/math_opt/model_update.proto", :proto_math_opt_model_update),
    FileProduct("include/ortools/math_opt/parameters.proto", :proto_math_opt_parameters),
    FileProduct("include/ortools/math_opt/result.proto", :proto_math_opt_result),
    FileProduct("include/ortools/math_opt/solution.proto", :proto_math_opt_solution),
    FileProduct("include/ortools/math_opt/solvers/glpk.proto", :proto_math_opt_solvers_glpk),
    FileProduct("include/ortools/math_opt/solvers/gscip/gscip.proto", :proto_math_opt_solvers_gscip),
    FileProduct("include/ortools/math_opt/solvers/gurobi.proto", :proto_math_opt_solvers_gurobi),
    FileProduct("include/ortools/math_opt/solvers/highs.proto", :proto_math_opt_solvers_highs),
    FileProduct("include/ortools/math_opt/solvers/osqp.proto", :proto_math_opt_solvers_osqp),
    FileProduct("include/ortools/math_opt/solvers/xpress.proto", :proto_math_opt_solvers_xpress),
    FileProduct("include/ortools/math_opt/sparse_containers.proto", :proto_math_opt_sparse_containers),
    FileProduct("include/ortools/packing/multiple_dimensions_bin_packing.proto", :proto_packing_multiple_dimensions_bin_packing),
    FileProduct("include/ortools/packing/vbp/vector_bin_packing.proto", :proto_packing_vector_bin_packing),
    FileProduct("include/ortools/pdlp/solve_log.proto", :proto_pdlp_solve_log),
    FileProduct("include/ortools/pdlp/solvers.proto", :proto_pdlp_solvers),
    FileProduct("include/ortools/sat/boolean_problem.proto", :proto_sat_boolean_problem),
    FileProduct("include/ortools/sat/cp_model.proto", :proto_sat_cp_model),
    FileProduct("include/ortools/sat/lrat.proto", :proto_sat_lrat),
    FileProduct("include/ortools/sat/sat_parameters.proto", :proto_sat_parameters),
    FileProduct("include/ortools/scheduling/course_scheduling.proto", :proto_scheduling_course_scheduling),
    FileProduct("include/ortools/scheduling/jobshop_scheduling.proto", :proto_scheduling_jobshop_scheduling),
    FileProduct("include/ortools/scheduling/rcpsp/rcpsp.proto", :proto_scheduling_rcpsp),
    FileProduct("include/ortools/util/optional_boolean.proto", :optional_boolean),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # OR-Tools deps require CMake >= 3.25
    # See: https://github.com/google/or-tools/blob/v9.15/cmake/dependencies/CMakeLists.txt#L16
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = "3.28.1")),
    # OR-Tools needs a dlopen-compatible shim on Windows
    # See: https://github.com/google/or-tools/issues/4073
    Dependency("dlfcn_win32_jll"; platforms = filter(Sys.iswindows, platforms)),
]

# Require macOS SDK 10.15 for complete C++17 filesystem support on x86_64
# See: https://developer.apple.com/documentation/xcode_release_notes/xcode_11_release_notes
sources, script = require_macos_sdk("10.15", sources, script)

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"11", julia_compat = "1.9")

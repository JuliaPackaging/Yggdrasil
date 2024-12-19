# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ORTools"
version = v"9.11"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/google/or-tools.git",
              "8edc858e5cbe8902801d846899dc0de9be748b2c")
]

# Bash recipe for building across all platforms
script = raw"""
# Prepare the source directory.
cd $WORKSPACE/srcdir/or-tools*
mkdir build
cmake --version

# Make the host compile tools easily accessible when cross-compiling.
# Otherwise, CMake will use the cross-compiler for host tools.
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

# Build OR-Tools.
cmake -S. -Bbuild \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_DEPS:BOOL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_SAMPLES:BOOL=OFF \
    -DUSE_SCIP:BOOL=OFF \
    -DUSE_HIGHS:BOOL=OFF \
    -DUSE_COINOR:BOOL=OFF \
    -DUSE_GLPK:BOOL=OFF
cmake --build build
cmake --build build --target install

# Finish installing: the ProtoBuf definitions.
install -Dvm 644 ortools/bop/bop_parameters.proto ${prefix}/include/ortools/bop/bop_parameters.proto
install -Dvm 644 ortools/constraint_solver/assignment.proto ${prefix}/include/ortools/constraint_solver/assignment.proto
install -Dvm 644 ortools/constraint_solver/demon_profiler.proto ${prefix}/include/ortools/constraint_solver/demon_profiler.proto
install -Dvm 644 ortools/constraint_solver/search_limit.proto ${prefix}/include/ortools/constraint_solver/search_limit.proto
install -Dvm 644 ortools/constraint_solver/search_stats.proto ${prefix}/include/ortools/constraint_solver/search_stats.proto
install -Dvm 644 ortools/constraint_solver/solver_parameters.proto ${prefix}/include/ortools/constraint_solver/solver_parameters.proto
install -Dvm 644 ortools/constraint_solver/routing_enums.proto ${prefix}/include/ortools/constraint_solver/routing_enums.proto
install -Dvm 644 ortools/constraint_solver/routing_parameters.proto ${prefix}/include/ortools/constraint_solver/routing_parameters.proto
install -Dvm 644 ortools/glop/parameters.proto ${prefix}/include/ortools/glop/parameters.proto
install -Dvm 644 ortools/graph/flow_problem.proto ${prefix}/include/ortools/graph/flow_problem.proto
install -Dvm 644 ortools/gscip/gscip.proto ${prefix}/include/ortools/gscip/gscip.proto
install -Dvm 644 ortools/linear_solver/linear_solver.proto ${prefix}/include/ortools/linear_solver/linear_solver.proto
install -Dvm 644 ortools/math_opt/callback.proto ${prefix}/include/ortools/math_opt/callback.proto
install -Dvm 644 ortools/math_opt/infeasible_subsystem.proto ${prefix}/include/ortools/math_opt/infeasible_subsystem.proto
install -Dvm 644 ortools/math_opt/model.proto ${prefix}/include/ortools/math_opt/model.proto
install -Dvm 644 ortools/math_opt/model_parameters.proto ${prefix}/include/ortools/math_opt/model_parameters.proto
install -Dvm 644 ortools/math_opt/model_update.proto ${prefix}/include/ortools/math_opt/model_update.proto
install -Dvm 644 ortools/math_opt/result.proto ${prefix}/include/ortools/math_opt/result.proto
install -Dvm 644 ortools/math_opt/solution.proto ${prefix}/include/ortools/math_opt/solution.proto
install -Dvm 644 ortools/math_opt/parameters.proto ${prefix}/include/ortools/math_opt/parameters.proto
install -Dvm 644 ortools/math_opt/solvers/glpk.proto ${prefix}/include/ortools/math_opt/solvers/glpk.proto
install -Dvm 644 ortools/math_opt/solvers/gurobi.proto ${prefix}/include/ortools/math_opt/solvers/gurobi.proto
install -Dvm 644 ortools/math_opt/solvers/highs.proto ${prefix}/include/ortools/math_opt/solvers/highs.proto
install -Dvm 644 ortools/math_opt/sparse_containers.proto ${prefix}/include/ortools/math_opt/sparse_containers.proto
install -Dvm 644 ortools/packing/multiple_dimensions_bin_packing.proto ${prefix}/include/ortools/packing/multiple_dimensions_bin_packing.proto
install -Dvm 644 ortools/packing/vector_bin_packing.proto ${prefix}/include/ortools/packing/vbp/vector_bin_packing.proto
install -Dvm 644 ortools/pdlp/solve_log.proto ${prefix}/include/ortools/pdlp/solve_log.proto
install -Dvm 644 ortools/pdlp/solvers.proto ${prefix}/include/ortools/pdlp/solvers.proto
install -Dvm 644 ortools/sat/cp_model.proto ${prefix}/include/ortools/sat/cp_model.proto
install -Dvm 644 ortools/sat/sat_parameters.proto ${prefix}/include/ortools/sat/sat_parameters.proto
install -Dvm 644 ortools/sat/boolean_problem.proto ${prefix}/include/ortools/sat/boolean_problem.proto
install -Dvm 644 ortools/util/optional_boolean.proto ${prefix}/include/ortools/util/optional_boolean.proto
install -Dvm 644 ortools/scheduling/course_scheduling.proto ${prefix}/include/ortools/scheduling/course_scheduling.proto
install -Dvm 644 ortools/scheduling/rcpsp.proto ${prefix}/include/ortools/scheduling/rcpsp/rcpsp.proto
install -Dvm 644 ortools/scheduling/jobshop_scheduling.proto ${prefix}/include/ortools/scheduling/jssp/jobshop_scheduling.proto
"""

platforms = [
    Platform("x86_64", "linux"),
    # Platform("aarch64", "linux"),   # Abseil uses -march for some files.
    # Platform("x86_64", "macos"),    # Abseil uses -march for some files.
    # Platform("aarch64", "macos"),   # Abseil uses -march for some files.
    Platform("x86_64", "freebsd"),  # Requires Clang 16+.
    # Platform("x86_64", "windows"),  # Requires dlfcn.h.
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libortools", :libortools),
    LibraryProduct("libortools_flatzinc", :libortools_flatzinc),
    
    ExecutableProduct("fzn-cp-sat", :fzncpsat),
    ExecutableProduct("sat_runner", :sat_runner),
    ExecutableProduct("solve", :solve),

    # Protocol Buffers definitions. Their position depends on the name space, but the symbol name includes the module the definitions come from.
    # - From bop/
    FileProduct("include/ortools/bop/bop_parameters.proto", :proto_bop_parameters),
    # - From constraint_solver/
    FileProduct("include/ortools/constraint_solver/assignment.proto", :proto_constraint_solver_assignment),
    FileProduct("include/ortools/constraint_solver/demon_profiler.proto", :proto_constraint_solver_demon_profiler),
    FileProduct("include/ortools/constraint_solver/search_limit.proto", :proto_constraint_solver_search_limit),
    FileProduct("include/ortools/constraint_solver/search_stats.proto", :proto_constraint_solver_search_stats),
    FileProduct("include/ortools/constraint_solver/solver_parameters.proto", :proto_constraint_solver_solver_parameters),
    FileProduct("include/ortools/constraint_solver/routing_enums.proto", :proto_constraint_solver_routing_enums),
    FileProduct("include/ortools/constraint_solver/routing_parameters.proto", :proto_constraint_solver_routing_parameters),
    # - From glop/
    FileProduct("include/ortools/glop/parameters.proto", :ortools_glop_parameters),
    # - From graph/
    FileProduct("include/ortools/graph/flow_problem.proto", :ortools_graph_flow_problem),
    # - From gscip/:
    FileProduct("include/ortools/gscip/gscip.proto", :proto_gscip),
    # - From linear_solver/
    FileProduct("include/ortools/linear_solver/linear_solver.proto", :proto_linear_solver),
    # - From math_opt/
    FileProduct("include/ortools/math_opt/callback.proto", :proto_math_opt_callback),
    FileProduct("include/ortools/math_opt/model.proto", :proto_math_opt_model),
    FileProduct("include/ortools/math_opt/model_parameters.proto", :proto_math_opt_model_parameters),
    FileProduct("include/ortools/math_opt/model_update.proto", :proto_math_opt_model_update),
    FileProduct("include/ortools/math_opt/result.proto", :proto_math_opt_result),
    FileProduct("include/ortools/math_opt/solution.proto", :proto_math_opt_solution),
    FileProduct("include/ortools/math_opt/parameters.proto", :proto_math_opt_parameters),
    FileProduct("include/ortools/math_opt/solvers/glpk.proto", :proto_math_opt_solvers_glpk),
    FileProduct("include/ortools/math_opt/solvers/gurobi.proto", :proto_math_opt_solvers_gurobi),
    FileProduct("include/ortools/math_opt/solvers/highs.proto", :proto_math_opt_solvers_highs),
    FileProduct("include/ortools/math_opt/sparse_containers.proto", :proto_math_opt_sparse_containers),
    FileProduct("include/ortools/math_opt/infeasible_subsystem.proto", :proto_math_opt_infeasible_subsystem),
    # - From packing/
    FileProduct("include/ortools/packing/multiple_dimensions_bin_packing.proto", :proto_packing_multiple_dimensions_bin_packing),
    FileProduct("include/ortools/packing/vbp/vector_bin_packing.proto", :proto_packing_vector_bin_packing),
    # - From pdlp/
    FileProduct("include/ortools/pdlp/solve_log.proto", :proto_pdlp_solve_log),
    FileProduct("include/ortools/pdlp/solvers.proto", :proto_pdlp_solvers),
    # - From sat/
    FileProduct("include/ortools/sat/cp_model.proto", :proto_sat_cp_model),
    FileProduct("include/ortools/sat/sat_parameters.proto", :proto_sat_parameters),
    FileProduct("include/ortools/sat/boolean_problem.proto", :proto_sat_boolean_problem),
    # FileProduct("include/ortools/sat/v1/cp_model_service.proto", :proto_sat_v1_cp_model_service),  # RPC definition.
    # - From util/
    FileProduct("include/ortools/util/optional_boolean.proto", :optional_boolean),
    # - From scheduling/
    FileProduct("include/ortools/scheduling/course_scheduling.proto", :proto_scheduling_course_scheduling),
    FileProduct("include/ortools/scheduling/rcpsp/rcpsp.proto", :proto_scheduling_rcpsp),
    FileProduct("include/ortools/scheduling/jssp/jobshop_scheduling.proto", :proto_scheduling_jobshop_scheduling),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"11", julia_compat="1.10")

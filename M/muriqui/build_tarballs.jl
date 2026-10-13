# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "muriqui"
version = v"0.7.5"

# Muriqui Optimizer is a solver for convex MINLP problems by Wendel Melo,
# Marcia Fampa and Fernanda Raupp. It ships an AMPL (.nl) driver, so it can be
# driven from JuMP through AmplNLWriter.jl.
#
# Upstream publishes no tags; this is the tree that self-reports "v0.7.05".
sources = [
    GitSource(
        "https://github.com/xmuriqui/muriqui.git",
        "ff1492c70e297077c9450ef9175e5a80c6627140",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/muriqui

################################################################################
# 0. Patches.
#
# MRQ_ExtCutPlan::resetOutput() assigns two members that are themselves declared
# under `#if MRQ_DEBUG_MODE`, so the release configuration does not compile
# upstream. Every other use of those members sits behind
# MRQ_CHECK_INT_SOLS_ARE_REPEATING, which is only defined when MRQ_DEBUG_MODE is
# on, so guarding the reset the same way is consistent with the surrounding code
# and is the whole of the fix -- with it, the release build is clean tree-wide.
################################################################################
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${f}"
done

################################################################################
# 1. Feature flags.
#
# WAXM_config.h is muriqui's master switchboard and every flag defaults to 0.
# Without this step the binary still builds, but refuses to do anything at
# runtime: "Error! AMPL Solver Library was not available in the compilation
# time!".
#
# In this tree the copies under codbb/ codminlpp/ codnumcomp/ codopt/ are git
# symlinks to the root file, so a single edit covers all of them. We sweep every
# copy anyway, which is idempotent while they are symlinks and still correct if a
# future revision turns them into real files.
#
# NB: the rootfs ships BusyBox sed, so no --follow-symlinks and no backreferences.
################################################################################
set_flag() { # $1 = macro name, $2 = value
    for f in $(find . -name WAXM_config.h); do
        sed -i "s|^#define $1[[:space:]].*|#define $1 $2|" "$f"
    done
}

set_flag WAXM_HAVE_ASL   1   # .nl reading / .sol writing -> ASL_jll
set_flag WAXM_HAVE_IPOPT 1   # NLP subsolver              -> Ipopt_jll
set_flag WAXM_HAVE_CBC   1   # MILP subsolver (default)   -> Cbc_jll
set_flag WAXM_HAVE_GLPK  1   # MILP subsolver (alternate) -> GLPK_jll
set_flag WAXM_DEBUG_MODE 0   # release: drops ~180 live asserts and debug printing

# Fail loudly rather than shipping a solver that cannot read .nl files.
for m in WAXM_HAVE_ASL WAXM_HAVE_IPOPT WAXM_HAVE_CBC WAXM_HAVE_GLPK; do
    grep -q "^#define ${m} 1" WAXM_config.h || exit 1
done

################################################################################
# 2. Dependency paths.
#
# Every dependency block in make.inc ships commented out. Rather than uncomment
# each one, append overrides: GNU make honours the last assignment, and all the
# aggregate variables (OPTSINC, MINLPPROBLIB, ...) use recursive `=` assignment,
# so they pick these up.
#
# muriqui's own expectations already match the JLL include layouts exactly:
#   ASL   -> flat headers in ${includedir}   (asl.h, getstub.h)
#   Ipopt -> ${includedir}/coin-or
#   Cbc   -> ${includedir}/coin
# so only the prefix has to be repointed.
################################################################################
# ASL's own extras are platform dependent: -lrt only exists on Linux (Ipopt's
# recipe does the same), -ldl exists on Linux and macOS but not on mingw, and on
# Windows clock_gettime -- used by the inline timers in codbb/BBL_tools.hpp and
# codopt/OPT_tools.hpp -- comes from winpthreads.
LIBASL="-lasl"
case "${target}" in
    *-linux-*)  LIBASL="${LIBASL} -lrt -ldl" ;;
    *-apple-*)  LIBASL="${LIBASL} -ldl"      ;;
    *-mingw*)   LIBASL="${LIBASL} -lpthread" ;;
esac

cat >> make.inc <<EOF

######################## Yggdrasil overrides ########################
ASLDIR = ${prefix}
ASLINC = -I${includedir}
ASLLIB = -L${libdir} ${LIBASL}

IPOPTDIR = ${prefix}
IPOPTINC = -I${includedir}/coin-or
IPOPTLIB = -L${libdir} -lipopt

CBCDIR = ${prefix}
CBCINC = -I${includedir}/coin
CBCLIB = -L${libdir} -lCbcSolver -lCbc -lOsiCbc -lCgl -lOsiClp -lClpSolver -lClp -lOsi -lCoinUtils

GLPKDIR = ${prefix}
GLPKINC = -I${includedir}
GLPKLIB = -L${libdir} -lglpk
EOF

################################################################################
# 3. Build.
#
# Toolchain variables are passed on the command line rather than appended to
# make.inc, for two reasons:
#   * command-line assignments beat the in-file ones unconditionally;
#   * AR_CMD is used as "$(AR_CMD)$(LIBNAME)", so it needs its trailing space
#     preserved -- fragile in a heredoc, safe as a quoted argument.
#
# The stock CXXFLAGS are "-O3 -m64 -march=native -Wall": -march=native would
# make the binary non-portable and -m64 breaks 32-bit targets, so both go.
# OpenMP is not needed -- WAXM_OMP_MULTITHREADING is never defined, so the
# MRQ_OMP_MULTITHREADING #if evaluates to 0 and threading is C++11 std::thread.
mrq_make() {
    make "$@" \
        CXX="${CXX}" \
        CXXFLAGS="-O3 -std=c++11 -fPIC" \
        CXXLINKFLAGS= \
        PARALEL= \
        AR_CMD="${AR:-ar} rv "
}

# The internal subpackages are built explicitly rather than through the `all`
# target: `all` chains "lib cleanexe muriqui", and the executable rule also
# depends on `sublibs`, which races under -j. codspm is header-only.
for d in codminlpp codbb codopt codnumcomp; do
    mrq_make -C "${d}" -j${nproc}
done
mrq_make -j${nproc} lib
mrq_make muriqui

################################################################################
# 4. Install. The Makefile's `install` target only handles static libs and
# headers, so the executable is installed by hand.
################################################################################
# The Makefile links with `-o $(EXE)`, and the PE linker appends .exe itself, so
# the produced name differs per platform.
exe=muriqui
[[ -f muriqui.exe ]] && exe=muriqui.exe
install -Dm755 "${exe}" "${bindir}/${exe}"
# Deliberately ${prefix}/lib and not ${libdir}: on Windows BB points libdir at
# bin (that is where DLLs belong), but this is a static archive, not a runtime
# library, so it goes to lib/ on every platform and FileProduct stays portable.
install -Dm644 libmuriqui.a "${prefix}/lib/libmuriqui.a"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Match the COIN-OR dependencies, which are cxxstring-ABI expanded.
platforms = expand_cxxstring_abis(platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(p -> arch(p) != "riscv64", platforms)
# muriqui is C++11 throughout.
filter!(p -> cxxstring_abi(p) != "cxx03", platforms)
# Windows is built through mingw, where WAXM_HAVE_POSIX stays 1 (it is only
# switched off for _MSC_VER). That is fine: the server/socket code lives in
# MRQ_server.cpp, which is not part of OBJS_LIB, and the only POSIX call left in
# what we build is clock_gettime, which mingw-w64 provides via winpthreads.

# The products that we will ensure are always built
products = [
    # Called amplexe to match the convention of the other AMPL-capable JLLs
    # (Ipopt_jll, SHOT_jll, Bonmin_jll, ...), which is what AmplNLWriter expects.
    ExecutableProduct("muriqui", :amplexe),
    FileProduct("lib/libmuriqui.a", :libmuriqui_a),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # .nl / .sol handling: muriqui calls ASL_alloc, jac0dim_ASL, pfgh_read_ASL
    # and write_sol_ASL, all exported by libasl.
    Dependency("ASL_jll", v"0.1.3"),
    # NLP subsolver.
    Dependency("Ipopt_jll", compat="300.1400.1901"),
    # MILP subsolver plus its COIN-OR stack: muriqui's Cbc wrapper uses the C++
    # API directly (CbcModel + OsiClpSolverInterface), so the whole chain is
    # needed at link time.
    Dependency("Cbc_jll", compat="200.1000.1200"),
    Dependency("Cgl_jll", compat="0.6000.900"),
    Dependency("Clp_jll", compat="100.1700.1001"),
    Dependency("Osi_jll", compat="0.10800.1100"),
    Dependency("CoinUtils_jll", compat="200.1100.1200"),
    # Alternate MILP subsolver.
    Dependency("GLPK_jll", compat="5.0.2"),
    # Reached transitively through Ipopt; declared so the BLAS is present.
    Dependency(
        PackageSpec(
            name = "libblastrampoline_jll",
            uuid = "8e850b90-86db-534c-a0d3-1478176c7d93",
        ),
        compat = "5.4.0",
    ),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)

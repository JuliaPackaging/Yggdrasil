# Recipe for FindMUS_jll: findMUS (https://gitlab.com/minizinc/FindMUS), the
# Minimal Unsatisfiable Subset (MUS / IIS) tool for MiniZinc. Given an
# unsatisfiable MiniZinc model it reports a minimal conflicting subset of
# constraints, running as a MiniZinc pseudo-solver.

using BinaryBuilder, Pkg

name = "FindMUS"
# findMUS has no release tags; findmus.msc reports 0.7.0, so pin a commit.
version = v"0.7.0"

sources = [
    GitSource(
        "https://gitlab.com/minizinc/FindMUS.git",
        "d986e4e114a11eddb7def41837f900e00845a800",
    ),
]

# find_package(libminizinc) resolves against MiniZinc_jll's
# lib/cmake/libminizinc config (shipped alongside lib/libmzn.a and
# include/minizinc/). CMAKE_POLICY_VERSION_MINIMUM placates the vendored
# MiniSat's pre-3.5 CMakeLists under modern CMake.
#
# findMUS's own targets include the vendored MiniSat's Options.h, which uses
# PRIi64 and INT64_MIN/INT64_MAX. MiniSat's CMakeLists defines
# __STDC_FORMAT_MACROS / __STDC_LIMIT_MACROS, but only in its subdirectory
# scope, so findMUS's sources fail to compile against the older-glibc and musl
# <inttypes.h>/<stdint.h>. Define both globally via CMAKE_CXX_FLAGS.
script = raw"""
cd $WORKSPACE/srcdir/FindMUS
# musl lacks glibc's <fpu_control.h>; the vendored MiniSat includes it under a
# bare __linux__ guard but only uses it (in System.cc) when _FPU_* are defined.
# Gate the include on __GLIBC__ so the build works on musl too.
sed -i 's/#if defined(__linux__)/#if defined(__linux__) \&\& defined(__GLIBC__)/' \
    mapsolvers/minisat/minisat/utils/System.h
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build --parallel ${nproc}
cmake --install build
"""

products = [
    ExecutableProduct("findMUS", :findMUS),
    # findmus.msc lets MiniZinc locate findMUS the way it locates Chuffed.
    FileProduct("share/minizinc/solvers/findmus.msc", :findmus_msc),
]

# findMUS statically links libmzn.a from MiniZinc_jll. Windows is excluded:
# findMUS's CMake cannot locate libminizinc in the MiniZinc_jll Windows artifact
# (libminizinc's own Windows support is a known work in progress), so drop all
# Windows platforms rather than ship a broken build.
platforms = expand_cxxstring_abis(
    supported_platforms(; exclude = Sys.iswindows),
)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # findMUS links MiniZinc_jll's libmzn.a, so this is an exact pin that must
    # move in lockstep with the MiniZinc_jll version.
    Dependency("MiniZinc_jll"; compat = "=2.9.5"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"6",  # matches MiniZinc_jll for ABI compatibility
    julia_compat = "1.10",
)

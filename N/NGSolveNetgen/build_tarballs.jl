# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Netgen, the mesh generator from the NGSolve project
# (https://github.com/NGSolve/netgen).
#
# NOTE: the bare name "Netgen" is already taken in the registry by an unrelated
# package (RTimothyEdwards/netgen, a VLSI layout-vs-schematic tool), so this
# JLL is named "NGSolveNetgen".
#
# This is a *headless* build: no GUI (Tcl/Tk/OpenGL) and no Python interface,
# but with the OpenCASCADE geometry kernel enabled (STEP/IGES/STL import) via
# OCCT_jll. It produces the core shared libraries libngcore and libnglib plus
# headers, suitable for linking from downstream C++/Julia code.
name = "NGSolveNetgen"
version = v"6.2.2606"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/NGSolve/netgen.git",
              "a3e08f0ec196b442f7de3b9b717ab86c6993f1ab"), # v6.2.2606
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/netgen

# Netgen builds a tiny code generator, `makerls`, and then invokes it by bare
# name during the build to turn its *.rls mesh-rule files into C++ sources.
# The in-tree target is built with the *target* toolchain (so it cannot run on
# the build host when cross-compiling) and the generation step calls it
# unqualified, relying on PATH. Compile a host-native copy and put it on PATH
# so the rule generation finds a runnable `makerls` on every platform.
mkdir -p ${WORKSPACE}/srcdir/hostbin
${HOSTCXX} -O2 -std=c++17 rules/makerlsfile.cpp -o ${WORKSPACE}/srcdir/hostbin/makerls
export PATH=${WORKSPACE}/srcdir/hostbin:${PATH}

# Netgen's ARM64 NEON SIMD path (libsrc/core/simd_arm64.hpp) uses Clang-only
# intrinsics (__builtin_shufflevector) and relies on implicit signed/unsigned
# NEON vector conversions, so it does not compile with GCC (used for the
# aarch64-linux targets). Restrict that header to Clang toolchains (macOS /
# FreeBSD arm64); GCC targets fall back to the portable generic SIMD code.
sed -i 's@#ifdef __aarch64__@#if defined(__aarch64__) \&\& defined(__clang__)@' libsrc/core/simd.hpp

# Netgen uses std::variant (e.g. in libsrc/meshing/meshtype.cpp), whose
# std::get / std::bad_variant_access is annotated as available only from
# macOS 10.14 in libc++. The x86_64-apple-darwin toolchain defaults to an
# older minimum (10.10), so bump it. (aarch64-apple-darwin already defaults
# to 11.0 and must not be lowered.)
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.15
fi

# Build directly (not the superbuild, which would try to download and build
# dependencies itself). Disable GUI and Python; enable the OpenCASCADE kernel,
# which is provided by OCCT_jll. NETGEN_VERSION_GIT is passed explicitly so the
# version does not depend on `git describe` at build time. The NG_INSTALL_DIR_*
# overrides force a standard prefix/lib|bin|include layout (otherwise Netgen
# installs into a macOS .app-style Contents/MacOS tree on Apple platforms).
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DNETGEN_VERSION_GIT=v6.2.2606-0-g0000000 \
    -DUSE_SUPERBUILD=OFF \
    -DUSE_NATIVE_ARCH=OFF \
    -DUSE_GUI=OFF \
    -DUSE_PYTHON=OFF \
    -DUSE_MPI=OFF \
    -DUSE_OCC=ON \
    -DUSE_JPEG=OFF \
    -DUSE_MPEG=OFF \
    -DUSE_CGNS=OFF \
    -DBUILD_STUB_FILES=OFF \
    -DNG_INSTALL_DIR_BIN=bin \
    -DNG_INSTALL_DIR_LIB=lib \
    -DNG_INSTALL_DIR_INCLUDE=include \
    -DNG_INSTALL_DIR_CMAKE=lib/cmake/netgen \
    -DNG_INSTALL_DIR_RES=share
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/netgen/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#
# Based on the platform set of OCCT_jll (our heaviest dependency): everything
# supported_platforms() returns except armv6l, with the C++ string ABI variants
# expanded since this is a C++ library.
#
# Windows is excluded: Netgen's Windows support targets MSVC, while
# BinaryBuilder uses mingw GCC, against which the sources do not currently
# compile (MSVC-only flags, Win32 API/_WIN32_WINNT and FARPROC conversions).
# This can be revisited as a follow-up.
platforms = supported_platforms()
platforms = filter!(p -> arch(p) != "armv6l" && !Sys.iswindows(p), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libngcore", :libngcore),
    LibraryProduct("libnglib", :libnglib),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    # Pin to OCCT_jll >= 7.9.3 (the current release). Netgen requires OCCT >= 7.8,
    # the version that introduced the modern toolkit names (TKDESTEP/TKDEIGES/
    # TKDESTL) it links against.
    Dependency("OCCT_jll"; compat="7.9.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")

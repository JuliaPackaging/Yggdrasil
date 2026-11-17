# Copyright (c) d-SEAMS developers
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libseams"
version = v"2.14.0"

# Annotated tag v2.14.0 on d-SEAMS/seams-core. The tag object is
# a54eee70f37da364f7abcbb49842b90b41d6ed07 and it points at this commit.
# BinaryBuilder refuses GitHub's generated archives (the bytes are not a
# stable hash), so the tree is pinned by that commit. The tag archive
# https://github.com/d-SEAMS/seams-core/archive/refs/tags/v2.14.0.tar.gz
# had sha256
# fa3e6d8f75e5a06691bd806334f1a89e0998f729d8145a057dc68794a162a551
# when downloaded on 2026-11-17.
const v2_14_0_tag_sha = "acc8bbc803f55bac39493c85300f87a8ce302829"

sources = [
    GitSource("https://github.com/d-SEAMS/seams-core.git", v2_14_0_tag_sha),
]

# The engine core, its stable C API (libseams), and the C ABI of the R and
# Julia packages (libseams_lang). Every optional backend is off: those come
# from wraps that would be downloaded during the build, or from libraries
# that have no JLL yet. The LAMMPS dump reader is native and does not need
# chemfiles. On a fresh tree, `meson setup` with `--wrap-mode=nodownload`
# skips the vesin wrap and still configures.
script = raw"""
cd ${WORKSPACE}/srcdir/seams-core

meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    --wrap-mode=nodownload \
    -Ddefault_library=shared \
    -Dwith_tests=false \
    -Dwith_cli=true \
    -Dwith_lammps=disabled \
    -Dwith_gromacs=disabled \
    -Dwith_openmm=disabled \
    -Dwith_plumed=disabled \
    -Dwith_mpi=disabled \
    -Dwith_gpulite=disabled \
    -Dwith_openmp_offload=disabled \
    -Dwith_ira=disabled \
    -Dwith_spglib=disabled \
    -Dwith_csm=disabled \
    -Dwith_sphericart=disabled \
    -Dwith_nauty=disabled \
    -Dwith_blas=disabled \
    -Dwith_chemfiles=disabled \
    -Dwith_readcon=disabled \
    -Dwith_linkcell=disabled \
    -Dwith_minimage=disabled
ninja -C build -j${nproc} src/libyodaLib.${dlext} src/libseams.${dlext} bindings/libseams_lang.${dlext} seams${exeext}

install -Dvm 755 build/src/libyodaLib.${dlext} "${libdir}/libyodaLib.${dlext}"
install -Dvm 755 build/src/libseams.${dlext} "${libdir}/libseams.${dlext}"
install -Dvm 755 build/bindings/libseams_lang.${dlext} "${libdir}/libseams_lang.${dlext}"
install -Dvm 755 build/seams${exeext} "${bindir}/seams${exeext}"
install -Dvm 644 include/seams.h "${includedir}/seams.h"
install -Dvm 644 build/src/seams_version.h "${includedir}/seams_version.h"
install -Dvm 644 bindings/cxx/seams_lang.h "${includedir}/seams/seams_lang.h"
install_license LICENSE
"""

# C++20 headers (<concepts>, <span>, <ranges>) are missing from the default
# macOS SDK.
sources, script = require_macos_sdk("14.5", sources, script; deployment_target = "11.0")

# __int128 in the CRT accumulator rules out 32-bit targets. The Windows and
# FreeBSD ports of the engine are not done yet.
platforms = supported_platforms(; exclude = p -> nbits(p) == 32 || Sys.iswindows(p) || Sys.isfreebsd(p))
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libyodaLib", :libyodaLib),
    LibraryProduct("libseams", :libseams),
    LibraryProduct("libseams_lang", :libseams_lang),
    ExecutableProduct("seams", :seams),
]

dependencies = [
    BuildDependency(PackageSpec(name = "Eigen_jll", uuid = "bc6bbf8a-a594-5541-9c57-10b0d0312c70",
                                version = "3.4")),
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll", uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms = filter(!Sys.isapple, platforms)),
    Dependency(PackageSpec(name = "LLVMOpenMP_jll", uuid = "1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms = filter(Sys.isapple, platforms)),
]

# C++20 (<numbers>, <span>, std::from_chars on integers) needs GCC 12 and,
# on macOS, LLVM 17.
# build_project_dict records uuid jll_uuid("libseams_jll"), which is
# 7f1e8526-9a03-57ab-a5c6-46114804ed15. Dseams already depends on that uuid.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"12",
               preferred_llvm_version = v"17")

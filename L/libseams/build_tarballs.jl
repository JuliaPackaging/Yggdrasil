# Copyright (c) d-SEAMS developers
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libseams"
version = v"2.14.2"

# The source archive carries the patched dependencies and Cargo vendor trees.
sources = [
    ArchiveSource("https://github.com/d-SEAMS/seams-core/releases/download/v$(version)/seams-core-$(version).tar.gz",
                  "4336e91c672f63c6b0a2dea9e05192c3cfcc9b0046b490958e646d56d1744e67"),
    DirectorySource(joinpath(@__DIR__, "bundled"); target = "seams-overlays"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/seams-core-*
atomic_patch -p1 ${WORKSPACE}/srcdir/seams-overlays/patches/cargo-cross-artifacts.patch
export CARGO_NET_OFFLINE=true
export CARGO_BUILD_TARGET="${rust_target}"
# LMDB and other C dependencies of Rust crates use the target compiler.
export "CC_${rust_target//-/_}=${target}-cc"
if [[ "${rust_target}" == x86_64-unknown-linux-gnu ]]; then
    # The cross sysroot uses zlib-compressed ELF sections.
    export RUSTFLAGS="${RUSTFLAGS:+${RUSTFLAGS} }-Clinker-features=-lld"
fi
export CMAKE_BUILD_PARALLEL_LEVEL=2
if [[ "${target}" == *apple* ]]; then
    export LIBOMP_PREFIX="${prefix}"
fi
export PATH="${host_bindir}:${PATH}"
cmake --version
# The nested Chemfiles install uses the private prefix selected by Meson.
sed '/^ *set(CMAKE_INSTALL_PREFIX /d' "${CMAKE_TARGET_TOOLCHAIN}" > seams-chemfiles-toolchain.cmake
cat > seams-chemfiles-cross.ini <<EOF
[properties]
cmake_toolchain_file = '${PWD}/seams-chemfiles-toolchain.cmake'
EOF

meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" --cross-file=seams-chemfiles-cross.ini \
    --buildtype=release --prefix="${prefix}" --libdir="${libdir}" \
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
    -Dwith_chemfiles=enabled -Duse_vendored_chemfiles=enabled \
    -Dwith_readcon=enabled \
    -Dwith_minimage=enabled \
    -Dwith_backward=auto
meson compile -C build -j 2

meson install -C build --no-rebuild
install_license LICENSE
cp subprojects/linkcell/LICENSE "${WORKSPACE}/srcdir/LICENSE.linkcell"
install_license "${WORKSPACE}/srcdir/LICENSE.linkcell"
cp third_party/argum/LICENSE "${WORKSPACE}/srcdir/LICENSE.argum"
install_license "${WORKSPACE}/srcdir/LICENSE.argum"
"""

# C++20 headers (<concepts>, <span>, <ranges>) are missing from the default
# macOS SDK.
sources, script = require_macos_sdk("14.5", sources, script; deployment_target = "11.0")

# The CRT accumulator requires 128-bit arithmetic. The recipe uses the
# compiler runtimes and OpenMP libraries available on the supported Unix targets.
platforms = supported_platforms(; exclude = p -> nbits(p) == 32 || Sys.iswindows(p) ||
                                                  Sys.isfreebsd(p) || arch(p) in ("powerpc64le", "riscv64"))
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libyodaLib", :libyodaLib),
    LibraryProduct("libseams", :libseams),
    LibraryProduct("libseams_lang", :libseams_lang),
    LibraryProduct("libreadcon_core", :libreadcon_core),
    LibraryProduct("libseams-chemfiles", :libseams_chemfiles),
    ExecutableProduct("seams", :seams),
]

dependencies = [
    Dependency("SQLite_jll"),
    HostBuildDependency(PackageSpec(name = "CMake_jll", version = "3.31.9")),
    BuildDependency(PackageSpec(name = "Eigen_jll", uuid = "bc6bbf8a-a594-5541-9c57-10b0d0312c70",
                                version = "3.4")),
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll", uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms = filter(!Sys.isapple, platforms)),
    Dependency(PackageSpec(name = "LLVMOpenMP_jll", uuid = "1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms = filter(Sys.isapple, platforms)),
]

# C++20 (<numbers>, <span>, std::from_chars on integers) needs GCC 12 and,
# on macOS, LLVM 17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", compilers = [:c, :rust], preferred_gcc_version = v"12",
               preferred_llvm_version = v"17", preferred_rust_version = v"1.91")

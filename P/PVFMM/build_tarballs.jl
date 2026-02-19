# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PVFMM"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    # develop branch head on 2026-02-17
    GitSource("https://github.com/dmalhotra/pvfmm.git", "77c87ef9796d358bc5dd703b5c16ee0f92bd1b59"),
    # SCTL submodule pinned by the pvfmm commit above
    GitSource("https://github.com/dmalhotra/SCTL.git", "06f26892ac1177eabec022d2e73ae737dd402975"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/pvfmm
rm -rf SCTL
cp -a ${WORKSPACE}/srcdir/SCTL ./SCTL

export MPITRAMPOLINE_CC=${CC}
export MPITRAMPOLINE_CXX=${CXX}
export MPITRAMPOLINE_FC=${FC}
export PKG_CONFIG_PATH="${libdir}/pkgconfig:${prefix}/lib/pkgconfig:${PKG_CONFIG_PATH}"

# On macOS hosts, AppleDouble metadata files can leak into mounted paths.
find /usr/share/cmake -name '._*' -delete || true

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH="${prefix}" \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DFFTW_ROOT=${prefix} \
    -DFFTW_DOUBLE_OPENMP_LIB=${libdir}/libfftw3.${dlext} \
    -DFFTW_FLOAT_OPENMP_LIB=${libdir}/libfftw3f.${dlext} \
    -DBLAS_LIBRARIES=-lopenblas \
    -DLAPACK_LIBRARIES=-lopenblas \
    -DMPI_C_COMPILER=${bindir}/mpicc \
    -DMPI_CXX_COMPILER=${bindir}/mpicxx

cmake --build build --parallel ${nproc}
cmake --install build

install_license COPYING
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# Linux-only for now: upstream requires GNU-style OpenMP and __float128 support.
platforms = filter(Sys.islinux, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5")

# Current upstream develop branch fails on non-x86 and musl targets in CI;
# keep the known-good Linux glibc x86 targets.
platforms = filter(p -> arch(p) in ("i686", "x86_64") && libc(p) == "glibc", platforms)

products = [
    LibraryProduct("libpvfmm", :libpvfmm),
]

dependencies = [
    Dependency("FFTW_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.11", preferred_gcc_version=v"14")

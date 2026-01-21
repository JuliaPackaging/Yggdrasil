# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "t8code"
version = v"4.0.0-26.01"
commit_hash = "a4572db2c7b8103dfba9e942c24acb923d735fdb"

sources = [GitSource("https://github.com/DLR-AMR/t8code", commit_hash),
           DirectorySource("./bundled")]

script = raw"""
cd $WORKSPACE/srcdir/T8CODE*

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mpi-constants.patch"

# Microsoft MPI is still 2.0 but has the required features; remove the strict 3.0 requirement
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mpi2.patch"

# Fixes for mingw, which is WIN32 for cmake, but uses Linux syntax
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mingw.patch"

# Show CMake where to find `mpiexec`.
if [[ "${target}" == *-mingw* ]]; then
  ln -s $(which mpiexec.exe) /workspace/destdir/bin/mpiexec
fi

cmake . \
      -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_CXX_FLAGS="-std=c++20" \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF \
      -DP4EST_BUILD_TESTING=OFF \
      -DSC_BUILD_TESTING=OFF \
      -DT8CODE_BUILD_BENCHMARKS=OFF \
      -DT8CODE_BUILD_DOCUMENTATION=OFF \
      -DT8CODE_BUILD_EXAMPLES=OFF \
      -DT8CODE_BUILD_FORTRAN_INTERFACE=OFF \
      -DT8CODE_BUILD_TESTS=OFF \
      -DT8CODE_BUILD_TUTORIALS=OFF \
      -DT8CODE_ENABLE_MPI=ON

make -C build -j ${nproc}
make -C build -j ${nproc} install
"""

# We need some C++20
# std::visit introduced in macOS 10.14, 'range' in namespace 'std::ranges' from 14.0 on
# target chosen as lowest working version
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="10.14")

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=false)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")

# Avoid platforms where the MPI implementation isn't supported
# MPItrampoline
#platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
#platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsc"], :libsc),
    LibraryProduct(["libp4est"], :libp4est),
    LibraryProduct(["libt8"], :libt8),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"12.1.0", clang_use_lld=false)

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "t8code"
version = v"3.0.0"

tarball = "https://github.com/DLR-AMR/t8code/releases/download/v$(version)/T8CODE-$(version)-Source.tar.gz"
sha256sum = "b60a30de342c4e0a00f84d1e910506babef4bd938d96d567714a9c1c26293cfb"

sources = [ArchiveSource(tarball, sha256sum), DirectorySource("./bundled")]

script = raw"""
cd $WORKSPACE/srcdir/T8CODE*

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mpi-constants.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/libsc.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/p4est.patch"

# Show CMake where to find `mpiexec`.
if [[ "${target}" == *-mingw* ]]; then
  ln -s $(which mpiexec.exe) /workspace/destdir/bin/mpiexec
fi

cmake . \
      -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF \
      -DP4EST_BUILD_TESTING=OFF \
      -DSC_BUILD_TESTING=OFF \
      -DT8CODE_BUILD_BENCHMARKS=OFF \
      -DT8CODE_BUILD_DOCUMENTATION=OFF \
      -DT8CODE_BUILD_EXAMPLES=OFF \
      -DT8CODE_BUILD_EXAMPLES=OFF \
      -DT8CODE_BUILD_TESTS=OFF \
      -DT8CODE_BUILD_TUTORIALS=OFF \
      -DT8CODE_ENABLE_MPI=ON \
      -DP4EST_ENABLE_MPIIO=OFF

make -C build -j ${nproc} # "${FLAGS[@]}" 
make -C build -j ${nproc} install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# p4est with MPI enabled does not compile for 32 bit Windows
platforms = filter(p -> !(Sys.iswindows(p) && nbits(p) == 32), platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")

# Disable OpenMPI since it doesn't build. This could probably be fixed
# via more explicit MPI configuraiton options.
platforms = filter(p -> p["mpi"] ≠ "openmpi", platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

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

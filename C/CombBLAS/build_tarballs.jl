# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "CombBLAS"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/PASSIONLab/CombBLAS.git",
        "e1c7faad8d5a918d5671b794c04672f30c6bec29",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/CombBLAS/
install_license LICENSE
mkdir build
cd build
# Prefer gcc over clang due to OpenMP concerns
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --parallel ${nproc} --target all
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(
    p -> !(Sys.iswindows(p) || Sys.isfreebsd(p) || libc(p) == "musl"),
    supported_platforms())
platforms, platform_dependencies =
    MPI.augment_platforms(platforms; MPItrampoline_compat = "5.2.1")

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(
    p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"),
    platforms,
)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)
platforms = expand_cxxstring_abis(platforms; skip = Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct("libCombBLAS", :libCombBLAS),
    LibraryProduct("libGraphGenlib", :libGraphGenlib),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        ),
    ),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well
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
    preferred_gcc_version = v"6",
)


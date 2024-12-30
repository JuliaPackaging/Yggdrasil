# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = (dirname∘dirname∘dirname)(@__FILE__)
(include∘joinpath)(YGGDRASIL_DIR, "platforms", "mpi.jl")

name = "FireFly"
version = v"2.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.com/firefly-library/firefly.git", "f0b0b316790fbe23b88dd7b759220944bc77302d")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $WORKSPACE/srcdir/FireFly-build
cd ${WORKSPACE}/srcdir/firefly
sed -i "s/TARGETS FireFly_static FireFly_shared/TARGETS FireFly_shared/g" CMakeLists.txt
cd $WORKSPACE/srcdir/FireFly-build

cmake -DWITH_FLINT=true \
    -DWITH_JEMALLOC=true \
    -DWITH_MPI=true \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ${EXTRA_CMAKE_FLAGS} \
    ${WORKSPACE}/srcdir/firefly

cmake --build . -j${nproc} -t install

install_license ${WORKSPACE}/srcdir/firefly/LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)
filter!(p -> nbits(p) ≠ 32, platforms)
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfirefly", :libfirefly)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")) # ensure that the correct version of libatomic @ x86_64-linux-gnu-cxx11-mpi+openmpi
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"); compat="6.2.0")
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    augment_platform_block,
    julia_compat="1.6",
    # preferred_gcc_version = v"5.2.0" # for std=c++14
    # preferred_gcc_version = v"6.1.0" # for making the target example
    preferred_gcc_version = v"7.1.0" # for avoiding unexpected segmentation fault on x86_64-linux-gnu-cxx11 @ Buildkite.com
)

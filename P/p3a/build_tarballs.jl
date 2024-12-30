# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "p3a"
version = v"1.0.3"
p3a_version = v"1.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sandialabs/p3a.git", "271cd1d77fbc850aa4ddfb015b59176926670b3b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/p3a/
mkdir build && cd build

CMAKE_FLAGS=()

#help find mpi on mingw, subset of https://github.com/JuliaPackaging/Yggdrasil/blob/b4fdb545c3954cff218051d7520c7418991d3416/T/TauDEM/build_tarballs.jl#L28-L53
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    CMAKE_FLAGS+=(
        -DMPI_HOME=${prefix}
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
        -DMPI_C_LIBRARIES=msmpi64
        -DMPI_CXX_LIBRARIES=msmpi64
    )
# elif [[ ${target} == *-apple-* ]]; then
#     CMAKE_FLAGS+=(
#         -DMPI_C_ADDITIONAL_INCLUDE_DIRS='' 
#         -DMPI_C_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi' 
#         -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS='' 
#         -DMPI_CXX_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi'
#     )
fi

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=OFF \
-DBUILD_SHARED_LIBS=ON \
-DKokkos_COMPILE_LANGUAGE=CXX \
"${CMAKE_FLAGS[@]}"

make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))
# Kokkos is only available on 64 bit
filter!(p -> nbits(p) != 32, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libp3a", :libp3a)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Kokkos_jll", uuid="c1216c3d-6bb3-5a2b-bbbf-529b35eba709"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isfreebsd, platforms))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
# needed a c++17 compiler, 7 and 8 kept refusing to acknowledge std::byte and a few other template things for some reason?!
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"9.1.0")

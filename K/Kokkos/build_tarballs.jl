# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kokkos"
version = v"3.5.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/kokkos/kokkos/archive/refs/tags/3.5.00.tar.gz", "748f06aed63b1e77e3653cd2f896ef0d2c64cb2e2d896d9e5a57fec3ff0244ff"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/kokkos-*

OPENMP_FLAG=()

#inspired by https://github.com/JuliaPackaging/Yggdrasil/blob/b15a45949bf007072af7a2f335fe6e49165f7627/E/Entwine/build_tarballs.jl#L31-L40
if [[ ${target} == *-linux-musl* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/disable-stacktrace-macro.patch

elif [[  ${target} == *-mingw*  ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-lowercase-windows-include.patch

elif [[  ${target} == *-apple-*  ]]; then
# Apple's Clang does not support OpenMP? - taken from AMRex build_tarballs.jl
    OPENMP_FLAG+=(-DKokkos_ENABLE_OPENMP=OFF)
else
    OPENMP_FLAG+=(-DKokkos_ENABLE_OPENMP=ON)
fi

mkdir build
cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=ON \
"${OPENMP_FLAG[@]}"

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
#Kokkos assumes a 64-bit build, remove 32-bit platforms
filter!(p -> nbits(p) != 32, platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libkokkoscore", :libkokkoscore),
    LibraryProduct("libkokkoscontainers", :libkokkoscontainers)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#minimum supported gcc on x86_64 is 5.3.0, BB only has 5.2.0 so we bump up to 6
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")

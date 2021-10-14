# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Kokkos"
version = v"3.4.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/kokkos/kokkos/archive/refs/tags/3.4.01.tar.gz", "146d5e233228e75ef59ca497e8f5872d9b272cb93e8e9cdfe05ad34a23f483d1"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/kokkos-*

#inspired by https://github.com/JuliaPackaging/Yggdrasil/blob/b15a45949bf007072af7a2f335fe6e49165f7627/E/Entwine/build_tarballs.jl#L31-L40
if [[ ${target} == *-linux-musl* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/musl-disable-stacktrace-macro.patch

elif [[  ${target} == *-mingw*  ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-lowercase-windows-include.patch
fi

mkdir build
cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=ON \
-DKokkos_ENABLE_OPENMP=ON

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
#Kokkos assumes a 64-bit build, remove 32-bit platforms
filter!(p -> nbits(p) != 32, platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libkokkoscore", :libkokkoscore),
    LibraryProduct("libkokkoscontainers", :libkokkoscontainers)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#minimum supported gcc on x86_64 is 5.3.0, BB only has 5.2.0 so we bump up to 6
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "primecount"
version = v"6.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kimwalisch/primecount.git", "fe433f39fa16eaeab41d7caaef90a9caefa32474"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/primecount/
atomic_patch -p1 ../patches/0001-Allow-disabling-building-static-library-for-Windows.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# code contains std::string values, this is needed for GCC 4/5 version boundary compat
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("primecount", :primecount),
    LibraryProduct("libprimecount", :libprimecount),
    LibraryProduct("libprimesieve", :libprimesieve),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")

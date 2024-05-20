# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "manifold"
version = v"2.4.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/elalish/manifold.git", "6d932a2c7f3a269f6d280545487131c38d05f0ee"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/manifold
mkdir build
cd build/
git submodule update --init --recursive
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMANIFOLD_PAR=NONE \
    -DMANIFOLD_TEST=OFF \
    -DBUILD_TEST_CGAL=OFF \
    -DMANIFOLD_PYBIND=OFF \
    -DMANIFOLD_JSBIND=OFF \
    -DMANIFOLD_EXPORT=OFF \
    -DBUILD_SHARED_LIBS=ON
cmake --build . --parallel ${nproc}
cmake --install .
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]
 platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    # LibraryProduct("libClipper2", :libClipper2),
    # LibraryProduct("libmanifold", :libmanifold),
    # LibraryProduct("libglm", :libglm),
    LibraryProduct("libmanifoldc", :libmanifoldc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# Needs for gcc: version
# * C++17: >= 7.1
# * -Wno-alloc-size-larger-than
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.5")

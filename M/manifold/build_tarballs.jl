# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "manifold"
version = v"2.4.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/elalish/manifold.git", "6d932a2c7f3a269f6d280545487131c38d05f0ee"),
    DirectorySource("./bundled/"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/manifold

# Fix CMake for Clipper2 on Windows
# Sent upstream in https://github.com/elalish/manifold/pull/815
atomic_patch -p1 $WORKSPACE/srcdir/patches/cmake_import_lib.patch

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
platforms = supported_platforms()
platforms = filter(platforms) do p
    !Sys.isfreebsd(p) && libc(p) != "musl"
end
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    # LibraryProduct("libmanifold", :libmanifold),
    LibraryProduct("libmanifoldc", :libmanifoldc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenGLMathematics_jll")
    Dependency("Clipper2_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
# Needs for gcc: version
# * C++17: >= 7.1
# * -Wno-alloc-size-larger-than
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10")

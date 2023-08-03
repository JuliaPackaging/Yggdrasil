# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "VCDiff"
version = v"0.8.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/open-vcdiff.git", "868f459a8d815125c2457f8c74b12493853100f9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/open-vcdiff/
git submodule update --init --recursive
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -Dvcdiff_build_exec=OFF \
    -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libvcdcom", :libvcdcom),
    LibraryProduct("libvcdenc", :libvcdenc),
    LibraryProduct("libvcddec", :libvcddec)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

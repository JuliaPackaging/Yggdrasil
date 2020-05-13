using BinaryBuilder

name = "nlopt"
version = v"2.6.2"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/stevengj/nlopt.git",
              "41967f1981d82d8495c0b27151a126bc35ae0d96"), # v2.6.2
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlopt
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DNLOPT_PYTHON=Off -DNLOPT_OCTAVE=Off -DNLOPT_MATLAB=Off -DNLOPT_GUILE=Off -DNLOPT_SWIG=Off -DNLOPT_LINK_PYTHON=Off ..
make && make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlopt", :libnlopt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

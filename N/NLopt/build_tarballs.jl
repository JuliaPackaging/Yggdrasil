using BinaryBuilder

name = "NLopt"
version = v"2.9.0"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/stevengj/nlopt.git",
              "c500b5044482b17cf0f85de1ca66d036efecf668"), # v2.9.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlopt
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DNLOPT_PYTHON=Off \
    -DNLOPT_OCTAVE=Off \
    -DNLOPT_MATLAB=Off \
    -DNLOPT_GUILE=Off \
    -DNLOPT_SWIG=Off \
    -DNLOPT_LINK_PYTHON=Off
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms()) # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlopt", :libnlopt),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

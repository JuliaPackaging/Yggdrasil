using BinaryBuilder

name = "ChibiScheme"
version = v"0.10"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/ashinn/chibi-scheme.git",
              "05eb4ebd357e2bf2fe5aa7da13b0422ce20ddf7f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/chibi-scheme
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libchibi-scheme", :libchibischeme),
    FileProduct("share/chibi/init-7.scm", :init_7_scm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

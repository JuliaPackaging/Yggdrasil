# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "lfr_benchmark"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/DiNiXi/lfr-benchmark-c.git", "a41befda585bc53f085e12df2b3eac960278b3cc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lfr-benchmark-c/lfr/
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release build
cd build/
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = expand_cxxstring_abis( filter!(p -> !Sys.iswindows(p), supported_platforms()) )
platforms = expand_cxxstring_abis( supported_platforms() )

# The products that we will ensure are always built
products = [
    LibraryProduct("liblfrsymmunwgt"   , :liblfrsymmunwgt   ),
    LibraryProduct("liblfrsymmwgt"     , :liblfrsymmwgt     ),
    LibraryProduct("liblfrnonsymmunwgt", :liblfrnonsymmunwgt),
    LibraryProduct("liblfrnonsymmwgt"  , :liblfrnonsymmwgt  ),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)

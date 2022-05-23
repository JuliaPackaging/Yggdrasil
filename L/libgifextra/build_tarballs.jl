# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GifLibExtra"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ashwani-rathee/GifLibExtra.git", "a5c74d671dbede5f4be5448f80a1fd6950ae38b7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/GifLibExtra.git/lib
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgifextra", :libgifextra)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Giflib_jll", uuid="59f7168a-df46-5410-90c8-f2779963d0ec"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

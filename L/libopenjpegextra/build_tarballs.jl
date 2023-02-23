# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libopenjpegextra"
version = v"0.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ashwani-rathee/libopenjpegextra.git", "f3b81edc36486bd3940ad46d242730907f20a575")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libopenjpegextra
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenjpegextra", :libopenjpegextra)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenJpeg_jll", uuid="643b3616-a352-519d-856d-80112ee9badc"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

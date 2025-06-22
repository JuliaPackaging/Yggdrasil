# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# This is the builder for the library Dierckx in Netlib
# (http://www.netlib.org/dierckx/), which doesn't really have a versin number.
name = "Dierckx"
upstream_version = "1.15.1"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/scipy/scipy/releases/download/v$(upstream_version)/scipy-$(upstream_version).tar.gz",
                  "033a75ddad1463970c96a88063a1df87ccfddd526437136b6ee81ff0312ebdf6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scipy-*/scipy/interpolate/fitpack
mkdir -p "${libdir}"
gfortran -o "${libdir}/libddierckx.${dlext}" -O3 -shared -fPIC *.f
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libddierckx", :libddierckx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

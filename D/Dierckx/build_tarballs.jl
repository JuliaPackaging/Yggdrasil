# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# This is the builder for the library Dierckx in Netlib
# (http://www.netlib.org/dierckx/), which doesn't really have a versin number.
name = "Dierckx"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/scipy/scipy/releases/download/v1.5.1/scipy-1.5.1.tar.xz",
                  "0728bd66a5251cfeff17a72280ae5a40ec14add217f94868d1415b3c469b610a"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

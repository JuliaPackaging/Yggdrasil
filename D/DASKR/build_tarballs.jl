# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DASKR"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.netlib.org/ode/daskr.tgz", "5472e98c954062ea69d19bd16d1cb8a8835497d6b0df18fe5753bae61d151774")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd DASKR
install_license LICENSE
mkdir $libdir
gfortran -shared -fPIC -o $libdir/daskr.${dlext} solver/d*.f
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_libgfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("daskr", :daskr)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
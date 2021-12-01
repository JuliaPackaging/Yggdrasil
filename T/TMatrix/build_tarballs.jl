# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TMatrix"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaRemoteSensing/TMatrix-fortran.git", "bf0d1bf15ff382b562427492895f8f3d0fb6b177")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TMatrix-fortran/
mkdir build && cd build
meson --cross-file=${MESON_TARGET_TOOLCHAIN}
meson install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libtmatrixro", :tmatrix_random_orientation),
    LibraryProduct("libtmatrixfo", :tmatrix_fixed_orientation)
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

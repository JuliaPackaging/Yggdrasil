# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Eiscor"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eiscor/eiscor.git", "696b90afcd8d637d080fe29de5c3c799bf5eb8dd")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eiscor*/
make -j${nproc} SLIB="${dlext}"
make INSTALLDIR="${libdir}" SLIB="${dlext}" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libeiscor", :libeiscor, "lib/eiscor/lib")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

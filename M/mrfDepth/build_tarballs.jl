# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mrfDepth"
version = v"1.0.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cran/mrfDepth.git", "6954d87f8ea3c87a2d945676233bf849af5aacd1")
]

# Bash recipe for building across all platforms
# License is GPL ( >= 2 ) according to DESCRIPTION
script = raw"""
cd ${WORKSPACE}/srcdir/mrfDepth/src
$FC -shared -fPIC *.f -o libmrfDepth.${dlext}
cp libmrfDepth.${dlext} ${libdir}
install_license /usr/share/licenses/GPL-2.0+
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmrfDepth", :libmrfDepth)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

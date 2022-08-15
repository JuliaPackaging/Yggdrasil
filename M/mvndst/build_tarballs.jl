# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mvndst"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://raw.githubusercontent.com/scipy/scipy/main/scipy/stats/mvndst.f", "51758c4f37153dd0d9eab2e002c0ec98c944551e05d5fed0e1900a711a0de1e0"),
    FileSource("https://raw.githubusercontent.com/scipy/scipy/main/LICENSE.txt", "86627b745e4937371bd5d3061a76b07501c0dd01e5c0ce2b2a9c25c9c1944f18")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p $libdir
install_license LICENSE.txt

SHAREFLAGS="-shared -fPIC"
OMPFLAGS="-fopenmp"
FLAGS="-cpp -fdefault-integer-8"
if [[ ${target} == *-apple-* ]]; then
    FLAGS+=" -static-libgfortran -lgfortran -lgcc -lSystem -nodefaultlibs"
fi
$FC -O3 ${SHAREFLAGS} ${OMPFLAGS} ${FLAGS} mvndst.f -o "${libdir}/libmvndst.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmvndst", :libmvndst)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

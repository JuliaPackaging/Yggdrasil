# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "glmnet"
version = v"5.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaStats/GLMNet.jl.git", "d8cab55556a8c184a879446476efcc35e68a3eee"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/GLMNet.jl/deps/

flags="-fdefault-real-8 -ffixed-form -shared -O3"
if [[ ${target} != *mingw* ]]; then
    flags="${flags} -fPIC"
fi
if [[ ${target} != aarch64* ]] && [[ ${target} != arm* ]]; then
    flags="${flags} -m${nbits}"
fi

${FC} ${LDFLAGS} ${flags} glmnet5.f90 -o libglmnet.${dlext}

mkdir -p $libdir
mv libglmnet.${dlext} $libdir/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libglmnet", :libglmnet)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

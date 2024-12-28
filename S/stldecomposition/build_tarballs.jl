# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "stldecomposition"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/SurajGupta/r-source.git", "a28e609e72ed7c47f6ddfbb86c85279a0750f0b7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/r-source/src/library/stats/src/

flags="-ffixed-form -shared -O3"
if [[ ${target} != *mingw* ]]; then
    flags="${flags} -fPIC";
fi
if [[ ${target} != aarch64* ]] && [[ ${target} != arm* ]]; then
    flags="${flags} -m${nbits}";
fi

mkdir -p ${libdir}

${FC} ${LDFLAGS} ${flags} stl.f -o ${libdir}/libstldecomposition.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libstldecomposition", :libstldecomposition)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

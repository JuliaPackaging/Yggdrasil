# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mineos"
version = v"1.0.1" # Artificial version number for bumping Julia compat (and expanding platforms)

# Collection of sources required to build Mineos
sources = [
    GitSource("https://github.com/anowacki/mineos.git", "e2558b486d7656ef112608a8776643da66dc87cf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mineos

# Fix clang error 'error: non-void function * should return a value [-Wreturn-type]'
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    export CFLAGS="-Wno-return-type"
fi

# Fix issue due to GCC 10+. Only necessary on aarch64-apple as others use earlier GCC
#     Error: Rank mismatch between actual argument at (1) and actual argument at (2) (scalar and rank-1)
if [[ "${target}" == aarch64-apple-* ]]; then
    export FFLAGS="-std=legacy"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-doc
make

make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("simpledit", :simpledit),
    ExecutableProduct("endi", :endi),
    ExecutableProduct("eigcon", :eigcon),
    ExecutableProduct("eigen2asc", :eigen2asc),
    ExecutableProduct("green", :green),
    ExecutableProduct("syndat", :syndat),
    ExecutableProduct("minos_bran", :minos_bran),
    ExecutableProduct("cucss2sac", :cucss2sac)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")


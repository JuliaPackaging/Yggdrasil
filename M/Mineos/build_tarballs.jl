# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Mineos"
version = v"1.0.2" 

# Collection of sources required to build Mineos
sources = [
    GitSource("https://github.com/geodynamics/mineos.git", "3dd7c7433766d630b929d8254d03e705808ff8a3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mineos

# Drop docs build target
atomic_patch -p1 ../patches/drop_docs.diff

autoupdate
autoreconf --install
# Fix clang error 'error: non-void function * should return a value [-Wreturn-type]'
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    export CFLAGS="-Wno-return-type"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
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
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")


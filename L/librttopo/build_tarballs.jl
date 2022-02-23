# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "librttopo"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.osgeo.org/librttopo/src/librttopo-$(version).tar.gz", "a77d8b787ba13f685de819348d5146f9f6ec56fd3bcf71e880dfc5e0086d4cb0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librttopo*

if [[ ${target} == *-freebsd* ]]; then
    export CPPFLAGS="-I${includedir}"
fi

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target}

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("librttopo", :librttopo)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GEOS_jll"; compat="~3.9")
]

# Build the tarballs, and possibly a `build.jl` as well.
#GEOS uses gcc6
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")

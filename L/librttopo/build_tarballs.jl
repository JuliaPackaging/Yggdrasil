# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "librttopo"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.osgeo.org/gitea/rttopo/librttopo.git", "ffcdc7ee67375c5874b09101dca3fc9fc98ecc08")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librttopo/

./autogen.sh

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
    Dependency(PackageSpec(name="GEOS_jll", uuid="d604d12d-fa86-5845-992e-78dc15976526"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#GEOS uses gcc6
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")

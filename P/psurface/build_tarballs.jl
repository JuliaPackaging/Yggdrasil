# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "psurface"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/psurface/psurface/archive/refs/tags/psurface-$(version).tar.gz", "b9259d616ff381c3c10402779dc61acfe3286d55b8f2c2a86fc262fc91cf1aa5"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/psurface-*

if [[ ${target} == *linux-musl* ]] || [[ ${target} == *mingw* ]]; then
    #this is fixed on master, if a new tag is released this can probably be removed
    sed -i 's/isnan/std::isnan/g' NormalProjector.cpp
    sed -i 's/isinf/std::isinf/g' NormalProjector.cpp
fi

if [[ ${target} == *x86_64-unknown-freebsd* ]]; then
    #these patches are derived directly from commits already merged on master, if a new tag is released these can probaly be removed
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/use-std-array-not-tr1-array.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/use-std-shared-ptr.patch
fi

autoreconf -vi

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target}

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental = true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libpsurface", :libpsurface),
    ExecutableProduct("psurface-simplify", :psurface_simplify),
    ExecutableProduct("psurface-smooth", :psurface_smooth),
    ExecutableProduct("psurface-convert", :psurface_convert)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
#gcc6 for std::isinf and std::isnan support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")

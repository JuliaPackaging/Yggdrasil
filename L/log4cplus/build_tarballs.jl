# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "log4cplus"
version = v"2.0.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/log4cplus/log4cplus/releases/download/REL_$(version.major)_$(version.minor)_$(version.patch)/log4cplus-$version.tar.gz",
                  "cdc3c738e00be84d8d03b580816b9f12628ecc1d71e1395080c802615d2d9ced")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/log4cplus-*

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-tests=no

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct(["liblog4cplusU", "liblog4cplusU-2-0"], :liblog4cplusU),
    LibraryProduct(["liblog4cplus", "liblog4cplus-2-0"], :liblog4cplus),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
#use v7 to avoid posix_memalign errors on `linux-musl` platforms
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")

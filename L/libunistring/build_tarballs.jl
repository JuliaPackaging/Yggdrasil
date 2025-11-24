# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libunistring"
version = v"1.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/libunistring/libunistring-$(version.major).$(version.minor).tar.gz",
                  "f7e39ddeca18858ecdd02c60d1d5374fcdcbbcdb6b68a391f8497cb1cb2cf3f7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libunistring-*

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
    LibraryProduct("libunistring", :libunistring)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

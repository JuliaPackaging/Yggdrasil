# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libidn"
version = v"1.38.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/libidn/libidn-$(version.major).$(version.minor).tar.gz", "de00b840f757cd3bb14dd9a20d5936473235ddcba06d4bc2da804654b8bbf0f6")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libidn-*

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target} \
--enable-static=no \
--enable-shared=yes \
--disable-doc

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libidn", :libidn),
    ExecutableProduct("idn", :idn)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

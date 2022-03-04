# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libidn2"
version = v"2.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/libidn/libidn2-$(version).tar.gz", "76940cd4e778e8093579a9d195b25fff5e936e9dc6242068528b437a76764f91")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libidn2*

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
    LibraryProduct("libidn2", :libidn2),
    ExecutableProduct("idn2", :idn2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
    Dependency(PackageSpec(name="libunistring_jll", uuid="6db05002-db9d-53dd-a359-17d4854bdf22"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libpsl"
version = v"0.21.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/rockdaboot/libpsl/releases/download/$(version)/libpsl-$(version).tar.gz",
                  "1dcc9ceae8b128f3c0b3f654decd0e1e891afc6ff81098f227ef260449dae208")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpsl*

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target} \
--enable-gtk-doc-html=no \
--enable-static=no \
--enable-shared=yes \
--enable-man=no

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libpsl", :libpsl),
    ExecutableProduct("psl", :psl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

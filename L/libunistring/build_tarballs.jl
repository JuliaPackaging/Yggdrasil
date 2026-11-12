# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libunistring"
version_str = "1.5"
version = VersionNumber(version_str)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/libunistring/libunistring-$(version_str).tar.xz",
                  "fe89007a8a414ae4790b816b86859e877d3ab135db3c37f06541ff7e85ac344b")
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

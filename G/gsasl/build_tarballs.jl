# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gsasl"
version = v"1.11.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://alpha.gnu.org/gnu/gsasl/gsasl-$(version).tar.gz", "96013602e2d81390cc6cef7a44d5cf8f07571eb415ba2ba99abbdf6ec6d1cf8e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gsasl-*

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target}

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libgsasl", :libgsasl),
    ExecutableProduct("gsasl", :gsasl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

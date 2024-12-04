# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libposit"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/takum-arithmetic/libposit.git", "84f00df366cd73a03696faeb47fbad922440986f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libposit
./configure
make PREFIX=${prefix} LDCONFIG= -j${nproc} install
rm -f ${prefix}/lib/libposit.a ${prefix}/lib/libposit.lib ${prefix}/share/man/man3/posit*.3 ${prefix}/share/man/man7/libposit.7
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libposit", :libposit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

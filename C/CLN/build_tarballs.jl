# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CLN"
version = v"1.3.6"

# Collection of sources required to complete build
sources = [
    GitSource("git://www.ginac.de/cln.git", "d4621667b173aa197a2b23d63f561648c0ee2968")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cln/

apk add texinfo

./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = Product[
    LibraryProduct("libcln", :libcln),
    ExecutableProduct("pi", :cln_pi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

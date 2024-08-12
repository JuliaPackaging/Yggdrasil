# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gzip"
version = v"1.13.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gzip/gzip-$(version.major).$(version.minor).tar.xz",
                  "7454eb6935db17c6655576c2e1b0fabefd38b4d0936e0f87f48cd062ce91a057"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gzip-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
if [[ "$target" == *-mingw* ]]; then
    sed "s/LIBS =/LIBS = -lssp/g" -i Makefile
fi
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gzip", :gzip)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

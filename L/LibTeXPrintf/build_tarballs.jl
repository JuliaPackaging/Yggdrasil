# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibTeXPrintf"
version = v"1.21"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bartp5/libtexprintf.git", "8bdbf8afdcbf305a5f1a1cef8fcaedab6c26d6fa"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libtexprintf/
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no --enable-shared=yes --enable-fast-install=yes
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtexprintf", :libtexprintf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

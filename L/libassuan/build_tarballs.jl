# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libassuan"
version = v"2.5.5"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libassuan/libassuan-$(version).tar.bz2",
                  "8e8c2fcc982f9ca67dcbb1d95e2dc746b1739a4668bc20b3a3c5be632edb34e4"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/libassuan-*/
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libassuan", :libassuan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libgpg_error_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

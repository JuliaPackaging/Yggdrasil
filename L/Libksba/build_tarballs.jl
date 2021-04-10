# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libksba"
version = v"1.5.1"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/libksba/libksba-$(version).tar.bz2",
                  "b0f4c65e4e447d9a2349f6b8c0e77a28be9531e4548ba02c545d1f46dc7bf921"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/libksba-*/
export CPPFLAGS="-I${prefix}/include"
./configure --prefix=${prefix} --host=${target} --with-libgpg-error-prefix=${prefix} --build=${MACHTYPE}
make -j${nproc} "${FLAGS[@]}"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms(exclude = Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libksba", :libksba),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libgpg_error_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

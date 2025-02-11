# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibMPDec"
mpdecimal_version = v"2.5.1"
version = v"2.5.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-$(mpdecimal_version).tar.gz",
                  "9f9cd4c041f99b5c49ffb7b59d9f12d95b683d88585608aa56a6307667b2b21f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpdecimal*/

# Give somewhat reasonable names to libraries for Windows
atomic_patch -p1 ../patches/01-libname-windows.patch
# By default use `${CC}` as linker
atomic_patch -p1 ../patches/02-linker-cc.patch
autoreconf -fiv

export CFLAGS="-std=gnu99"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-cxx
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpdec", :libmpdec)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

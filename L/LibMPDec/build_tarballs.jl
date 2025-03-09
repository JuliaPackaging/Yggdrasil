# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibMPDec"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-$(version).tar.gz",
                  "942445c3245b22730fd41a67a7c5c231d11cb1b9936b9c0f76334fb7d0b4468c"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpdecimal*

#TODO # Give somewhat reasonable names to libraries for Windows
#TODO atomic_patch -p1 ../patches/01-libname-windows.patch
# By default use `${CC}` as linker
atomic_patch -p1 ../patches/02-linker-cc.patch

autoreconf -fiv

#TODO export CFLAGS="-std=gnu99"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-cxx \
    --disable-doc \
    --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # A C++ version is available as well. We don't build it (yet?) because there doesn't seem to be a need (yet?).
    LibraryProduct("libmpdec", :libmpdec)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

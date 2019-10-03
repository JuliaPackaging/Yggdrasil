# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Keyutils"
version = v"1.6.1"

# Collection of sources required to build keyutils
sources = [
    "https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git/snapshot/keyutils-$(version).tar.gz" =>
    "3c71dcfc6900d07b02f4e061d8fb218a4ae6519c1d283d6a57b8e27718e2f557",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/keyutils-*/
make -j${nproc}
make install \
    DESTDIR="${prefix}/" \
    SBINDIR="bin" \
    BINDIR="bin" \
    LIBDIR="lib" \
    USRLIBDIR="lib" \
    INCLUDEDIR="include" \
    MANDIR="share/man" \
    SHAREDIR="share/keyutils"

# Fix broken symlink
ln -sf libkeyutils.so.1 ${prefix}/lib/libkeyutils.so
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libkeyutils", :libkeyutils),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

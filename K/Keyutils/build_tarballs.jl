# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Keyutils"
version = v"1.6.3"

# Collection of sources required to build keyutils
sources = [
    ArchiveSource("https://git.kernel.org/pub/scm/linux/kernel/git/dhowells/keyutils.git/snapshot/keyutils-$(version).tar.gz",
                  "a61d5706136ae4c05bd48f86186bcfdbd88dd8bd5107e3e195c924cfc1b39bb4"),
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
ln -sf libkeyutils.so.1 "${libdir}/libkeyutils.so"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms(; exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct("libkeyutils", :libkeyutils),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

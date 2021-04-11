# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GnuPG"
version = v"2.2.27"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/gnupg/gnupg-$(version).tar.bz2",
                  "34e60009014ea16402069136e0a5f63d9b65f90096244975db5cea74b3d02399"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/gnupg-*/
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} LDFLAGS=-Wl,-rpath-link=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgnupg"], :libgnupg),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GnuTLS_jll"),
    Dependency("Libksba_jll"),
    Dependency("Libgcrypt_jll"),
    Dependency("Libgpg_error_jll"),
    Dependency("nPth_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libassuan_jll"),
    Dependency("OpenLDAPClient_jll"),
    Dependency("Bzip2_jll"),
    Dependency("SQLite_jll"),
    Dependency("libusb_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
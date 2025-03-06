# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nPth"
version_string = "1.8"
version = VersionNumber(version_string)

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/npth/npth-$(version_string).tar.bz2",
                  "8bd24b4f23a3065d6e5b26e98aba9ce783ea4fd781069c1b35d149694e90ca3e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/npth-*
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --disable-static
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/npth-*/COPYING.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libnpth", "libnpth6"], :libnpth),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

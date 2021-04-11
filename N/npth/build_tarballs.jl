# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "npth"
version = v"1.6"

# Collection of sources required to build libgcrypt
sources = [
    ArchiveSource("https://gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2",
                  "1393abd9adcf0762d34798dc34fdcf4d0d22a8410721e76f1e3afcd1daa4e2d1"),
]

# Bash recipe for building across all platforms

# Tried -no-undefined but still couldn't build for windows
script = raw"""
cd $WORKSPACE/srcdir/npth-*/
if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi
update_configure_scripts

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
    LibraryProduct(["libnpth", "libnpath6"], :libnpth),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

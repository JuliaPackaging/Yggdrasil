using BinaryBuilder

name = "GnuTLS"
version = v"3.6.13"

# Collection of sources required to build GnuTLS
sources = [
    ArchiveSource("https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.13.tar.xz" =>
                  "32041df447d9f4644570cf573c9f60358e865637d69b7e59d1159b7240b52f38"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnutls-*/

# Grumble-grumble apple grumble-grumble broken linkers...
#if [[ ${target} == *-apple-* ]]; then
#    export AR=/opt/${target}/bin/ar
#fi

./configure --prefix=${prefix} --host=${target} \
    --with-included-libtasn1 \
    --with-included-unistring \
    --without-p11-kit 

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Wimp out of doing FreeBSD since we don't have that for some targets
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]

# Disable windows because O_NONBLOCK isn't defined
platforms = [p for p in platforms if !(typeof(p) <: Windows)]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgnutls", :libgnutls),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "GMP_jll",
    "Nettle_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

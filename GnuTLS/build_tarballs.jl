using BinaryBuilder

name = "GnuTLS"
version = v"3.6.5"

# Collection of sources required to build GnuTLS
sources = [
    "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.5.tar.xz" =>
    "073eced3acef49a3883e69ffd5f0f0b5f46e2760ad86eddc6c0866df4e7abb35",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnutls-*/

# Grumble-grumble apple grumble-grumble broken linkers...
if [[ ${target} == *-apple-* ]]; then
    export AR=/opt/${target}/bin/ar
fi

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
products = prefix -> [
    LibraryProduct(prefix, "libgnutls", :libgnutls),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/NettleHogweed-v3.4.1-0/build_Nettle.v3.4.1.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

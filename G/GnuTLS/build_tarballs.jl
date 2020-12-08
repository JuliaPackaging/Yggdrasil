using BinaryBuilder

name = "GnuTLS"
version = v"3.6.15"

# Collection of sources required to build GnuTLS
sources = [
    ArchiveSource("https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-$(version).tar.xz",
                  "0ea8c3283de8d8335d7ae338ef27c53a916f15f382753b174c18b45ffd481558"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnutls-*/

# Grumble-grumble apple grumble-grumble broken linkers...
#if [[ ${target} == *-apple-* ]]; then
#    export AR=/opt/${target}/bin/ar
#fi

GMP_CFLAGS="-I${prefix}/include" ./configure --prefix=${prefix} --host=${target} \
    --with-included-libtasn1 \
    --with-included-unistring \
    --without-p11-kit 

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable windows because O_NONBLOCK isn't defined
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgnutls", :libgnutls),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("Nettle_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", lock_microarchitecture=false)

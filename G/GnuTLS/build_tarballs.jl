using BinaryBuilder

name = "GnuTLS"
version = v"3.6.13"

# Collection of sources required to build GnuTLS
sources = [
    ArchiveSource("https://www.gnupg.org/ftp/gcrypt/gnutls/v$(version.major).$(version.minor)/gnutls-$(version).tar.xz",
                  "32041df447d9f4644570cf573c9f60358e865637d69b7e59d1159b7240b52f38"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnutls-*/

# Grumble-grumble apple grumble-grumble broken linkers...
#if [[ ${target} == *-apple-* ]]; then
#    export AR=/opt/${target}/bin/ar
#fi

GMP_CFLAGS="-I${prefix}/include" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
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
    Dependency("Nettle_jll", v"3.4.1"; compat="~3.4.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", lock_microarchitecture=false)

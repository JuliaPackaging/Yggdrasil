using BinaryBuilder

name = "GnuTLS"
version = v"3.7.1"

# Collection of sources required to build GnuTLS
sources = [
    ArchiveSource("https://www.gnupg.org/ftp/gcrypt/gnutls/v$(version.major).$(version.minor)/gnutls-$(version).tar.xz",
                  "3777d7963eca5e06eb315686163b7b3f5045e2baac5e54e038ace9835e5cac6f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnutls-*/

# Grumble-grumble apple grumble-grumble broken linkers...
#if [[ ${target} == *-apple-* ]]; then
#    export AR=/opt/${target}/bin/ar
#fi

if [[ ${target} == *darwin* ]]; then
    # Fix undefined reference to "_c_isdigit"
    # See https://gitlab.com/gnutls/gnutls/-/issues/1033
    atomic_patch -p1 ../patches/03-undo-libtasn1-cisdigit.patch

    # We need to explicitly request a higher `-mmacosx-version-min` here, so that it doesn't
    # complain about: `Symbol not found: ___isOSVersionAtLeast`
    if [[ "${target}" == aarch64* ]]; then
        export CFLAGS="-mmacosx-version-min=11.0"
    else
        export CFLAGS="-mmacosx-version-min=10.11"
    fi
fi

GMP_CFLAGS="-I${prefix}/include" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-included-libtasn1 \
    --with-included-unistring \
    --without-p11-kit 

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# Disable windows because O_NONBLOCK isn't defined
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgnutls", :libgnutls),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("Nettle_jll", v"3.7.2"; compat="~3.7.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", lock_microarchitecture=false, julia_compat="1.6")

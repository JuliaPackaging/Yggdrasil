using BinaryBuilder

name = "GnuTLS"
version = v"3.8.11"

# Collection of sources required to build GnuTLS
sources = [
    ArchiveSource("https://www.gnupg.org/ftp/gcrypt/gnutls/v$(version.major).$(version.minor)/gnutls-$(version).tar.xz",
                  "91bd23c4a86ebc6152e81303d20cf6ceaeb97bc8f84266d0faec6e29f17baa20"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnutls-*/

if [[ ${target} == *darwin* ]]; then
    # Fix undefined reference to "_c_isdigit"
    # See https://gitlab.com/gnutls/gnutls/-/issues/1033
    atomic_patch -p1 ../patches/03-undo-libtasn1-cisdigit.patch

    # We need to explicitly request a higher `-mmacosx-version-min` here, so that it doesn't
    # complain about: `Symbol not found: ___isOSVersionAtLeast`
    if [[ "${target}" == x86_64* ]]; then
        export CFLAGS="-mmacosx-version-min=10.11"
    fi
fi

if [[ ${target} == ${MACHTYPE} ]]; then
    # Remove libffi from the system to avoid confusion.
    rm /usr/lib/libffi.so*
fi

# Checks from macros `AC_FUNC_MALLOC` and `AC_FUNC_REALLOC` may fail when cross-compiling,
# which can cause configure to remap `malloc` and `realloc` to replacement functions
# `rpl_malloc` and `rpl_realloc`, which will cause a linking error.  For more information,
# see https://stackoverflow.com/q/70725646/2442087
FLAGS=(ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes)

export GMP_CFLAGS="-I${includedir}"
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-included-libtasn1 \
    --with-included-unistring \
    "${FLAGS[@]}"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Disable windows because O_NONBLOCK isn't defined
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgnutls", :libgnutls),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("GMP_jll", v"6.2.1"),
    Dependency("Nettle_jll"; compat="3.10.1"),
    Dependency("P11Kit_jll"; compat="0.25.10"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", lock_microarchitecture=false, preferred_gcc_version=v"11")

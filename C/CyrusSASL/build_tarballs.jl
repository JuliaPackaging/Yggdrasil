# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CyrusSASL"
version = v"2.1.29"          # We need to bump the version of the jll to compile with OpenSSL 3.0 instead of 1.1.10
library_version = v"2.1.28"  # But keep the CyrusSASL version as-is

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-$(library_version)/cyrus-sasl-$(library_version).tar.gz", "7ccfc6abd01ed67c1a0924b353e526f1b766b21f42d4562ee635a8ebfc5bb38c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cyrus-sasl-*/
if [[ "${target}" == *-mingw* ]]; then
    # Patches from
    # https://github.com/msys2/MINGW-packages/tree/0e912fe13aa3583d9afd2ec100ca6c285f553e8f/mingw-w64-cyrus-sasl
    cp ../patches/pathtools.* lib
    atomic_patch -p1 ../patches/04-manpage-paths.patch
    atomic_patch -p1 ../patches/16-MinGW-w64-define-WIN32_LEAN_AND_MEAN-avoiding-handle_t-redef.patch
    atomic_patch -p1 ../patches/19-paths-relocation.patch
    atomic_patch -p1 ../patches/20-mingw-tchar.patch
    atomic_patch -p1 ../patches/21-fix-getopt-guard.patch
    atomic_patch -p1 ../patches/22-autoconf-prevent-full-path-resolution.patch
    atomic_patch -p1 ../patches/23-Fix-building-digest-plugin.patch

    # Remove incompatible typedef
    atomic_patch -p1 ../patches/30-remove-extra-incompatible-typedef.patch
fi
if [[ "${target}" == *-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/macos-shared-lib-extension.patch
    atomic_patch -p1 ../patches/macos-libdigestmd5-links-libcrypto.patch
fi
autoreconf -vi
if [[ "${target}" == *-mingw* ]]; then
    # Copy the right header file for Windows into `include/`...
    cp win32/include/md5global.h include/md5global.h

    # ...and don't regenerate a wrong one with `make.  This patch needs to be
    # applied _after_ autoreconf, which seems to somehow revert the changes :-(
    atomic_patch -p1 ../patches/31-do-not-make-mdf5global_h.patch

    if [[ "${target}" == x86_64-* ]]; then
        # On x86_64 mingw32 the import libraries of OpenSSL are in `lib64/`.
        export LDFLAGS="-L${prefix}/lib64"
    fi
fi
./configure --prefix=${prefix} \
    --build=${MACHTYPE} --host=${target} \
    --with-openssl=${prefix} \
    --with-sqlite3=${prefix} \
    --oldincludedir=${includedir} \
    --enable-ntlm \
    --disable-gssapi \
    --with-dblib=gdbm \
    --disable-static \
    --disable-ldapdb \
    --without-saslauthd \
    --without-pwcheck \
    --without-des \
    --without-authdaemond \
    --disable-sample \
    --with-plugindir=${prefix}/lib/sasl2 \
    --with-configdir=${prefix}/etc/sasl2:${prefix}/etc/sasl:${prefix}/lib/sasl2
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libanonymous", :libanonymous, "lib/sasl2"),
    LibraryProduct("libplain", :libplan, "lib/sasl2"),
    LibraryProduct("libscram", :libscram, "lib/sasl2"),
    LibraryProduct("libotp", :libotp, "lib/sasl2"),
    LibraryProduct("libdigestmd5", :libdigestmd5, "lib/sasl2"),
    LibraryProduct("libcrammd5", :libcrammd5, "lib/sasl2"),
    LibraryProduct("libntlm", :libntlm, "lib/sasl2"),
    LibraryProduct("libsasl2", :libsasl2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
    Dependency(PackageSpec(name="Gdbm_jll", uuid="54ca2031-c8dd-5cab-9ed4-295edde1660f"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

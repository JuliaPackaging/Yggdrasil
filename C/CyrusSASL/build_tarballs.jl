# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CyrusSASL"
version = v"2.1.27"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz", "26866b1549b00ffd020f188a43c258017fa1c382b3ddadd8201536f72efb05d5"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cyrus-sasl-*/
if [[ "${target}" == *-mingw* ]]; then
  atomic_patch -p1 ../patches/02-exeext.patch
  atomic_patch -p1 ../patches/03-fix-plugins.patch
  atomic_patch -p1 ../patches/04-manpage-paths.patch
  atomic_patch -p1 ../patches/14-MinGW-w64-add-LIBSASL_API-to-function-definitions.patch
  atomic_patch -p1 ../patches/15-MinGW-w64-define-LIBSASL_EXPORTS_eq_1-for-sasldb.patch
  atomic_patch -p1 ../patches/16-MinGW-w64-define-WIN32_LEAN_AND_MEAN-avoiding-handle_t-redef.patch
  atomic_patch -p1 ../patches/17-MinGW-w64-define-S_IRUSR-and-S_IWUSR.patch
  atomic_patch -p1 ../patches/19-paths-relocation.patch
  atomic_patch -p1 ../patches/20-mingw-tchar.patch
  atomic_patch -p1 ../patches/21-fix-getopt-guard.patch

  cp win32/include/md5global.h include/md5global.h
fi
atomic_patch -p1 ../patches/macos-shared-lib-extension.patch
autoreconf -vi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-openssl=${prefix} --with-sqlite3=${prefix} --oldincludedir=${prefix}/include --enable-ntlm --disable-gssapi --with-dblib=gdbm --disable-static --disable-ldapdb --without-saslauthd --without-pwcheck --without-des --without-authdaemond --disable-sample --with-plugindir=${prefix}/lib/sasl2 --with-configdir=${prefix}/etc/sasl2:${prefix}/etc/sasl:${prefix}/lib/sasl2
make -j${nproc}
make install
install_license COPYING
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
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
    Dependency(PackageSpec(name="Gdbm_jll", uuid="54ca2031-c8dd-5cab-9ed4-295edde1660f"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

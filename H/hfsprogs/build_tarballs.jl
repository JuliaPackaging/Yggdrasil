using BinaryBuilder

name = "hfsprogs"
version = v"540.1.3" # upstream 540.1.linux3

sources = [
    # tag debian/540.1.linux3-5
    GitSource("https://salsa.debian.org/debian/hfsprogs.git", "856b5699b6703d6f09909655f20c55c4ed2133fe"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/hfsprogs

for p in $(grep -v '^#' debian/patches/series); do
    atomic_patch -p1 debian/patches/${p}
done
for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${p}
done

if [[ "${target}" == *freebsd* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/freebsd/0001-drop-apple-api-private.patch
fi

if [[ "${target}" == *-musl* ]]; then
    # musl has no <sys/cdefs.h>, which provides __P()
    export CFLAGS="${CFLAGS} -include ${WORKSPACE}/srcdir/compat/cdefs.h"
fi

if [[ "${target}" != *-linux-* ]]; then
    # The LINUX code path handles image files; supply the glibc headers it expects
    export CFLAGS="${CFLAGS} -I${WORKSPACE}/srcdir/compat"
fi

# The Makefile hardcodes GNU-ld-only LDFLAGS; fsck_hfs is not built
make -j${nproc} CC="${CC}" LDFLAGS="${LDFLAGS}" SUBDIRS="newfs_hfs.tproj"

install -Dvm 755 newfs_hfs.tproj/newfs_hfs "${bindir}/newfs_hfs"
install_license debian/copyright
"""

# No Windows port
platforms = filter(!Sys.iswindows, supported_platforms())

products = [
    ExecutableProduct("newfs_hfs", :newfs_hfs),
]

dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

# OpenSSL_jll's libcrypto needs glibc >= 2.17
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")

using BinaryBuilder

name = "LibUnwind"
version = v"1.5.0"

# XXX: The git tag for libunwind v1.5.0 is just v1.5 rather than v1.5.0. Check this
# when updating to the next libunwind version.
version_short = "1.5"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://github.com/libunwind/libunwind/releases/download/v$(version_short)/libunwind-$(version).tar.gz",
                  "90337653d92d4a13de590781371c604f9031cdb50520366aa1e3a91e1efb1017"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libunwind*/

# We need to massage configure script to convince it to build the shared library
# for PowerPC.
if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-prefer-extbl.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-static-arm.patch
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/libunwind-configure-ppc64le.patch
atomic_patch -p0 ${WORKSPACE}/srcdir/patches/libunwind-configure-static-lzma.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-cfa-rsp.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libunwind-dwarf-table.patch

CFLAGS="${CFLAGS} -DPI -fPIC -I${prefix}/include"
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    CFLAGS="${CFLAGS}" \
    --libdir=${libdir} \
    --enable-minidebuginfo \
    --enable-zlibdebuginfo \
    --disable-tests
make -j${nproc}
make install

# Shoe-horn liblzma.a into libunwind.a
mkdir -p unpacked/{liblzma,libunwind}
(cd unpacked/liblzma; ar -x ${prefix}/lib/liblzma.a)
(cd unpacked/libunwind; ar -x ${prefix}/lib/libunwind.a)
rm -f ${prefix}/lib/libunwind.a
ar -qc ${prefix}/lib/libunwind.a unpacked/**/*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  libunwind is only used
# on Linux or FreeBSD (e.g. ELF systems)
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libunwind", :libunwind),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("XZ_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")

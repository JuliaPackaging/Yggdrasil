using BinaryBuilder

name = "LibUnwind"
version = v"1.3.2"

# Collection of sources required to build libffi
sources = [
    ArchiveSource("https://github.com/libunwind/libunwind/releases/download/v$(version)/libunwind-$(version).tar.gz",
                  "0a4b5a78d8c0418dfa610245f75fa03ad45d8e5e4cc091915d2dbed34c01178e"),
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

CFLAGS="${CFLAGS} -DPI -fPIC -I${prefix}/include"
./configure --prefix=$prefix --host=$target CFLAGS="${CFLAGS}" --libdir=${libdir} --enable-minidebuginfo --disable-tests
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
platforms = [p for p in supported_platforms(;experimental=true) if Sys.islinux(p) || Sys.isfreebsd(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libunwind", :libunwind),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("XZ_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

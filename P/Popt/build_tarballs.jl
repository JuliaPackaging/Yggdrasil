# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Popt"
version = v"1.16.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://archive.ubuntu.com/ubuntu/pool/main/p/popt/popt_1.16.orig.tar.gz", "e728ed296fe9f069a0e005003c3d6b2dde3d9cad453422a10d6558616d304cc8"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd popt-1.16/
update_configure_scripts
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-nl_langinfo.mingw32.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/197416.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/217602.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/278402-manpage.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/318833.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/356669.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/367153-manpage.all.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/get-w32-console-maxcols.mingw32.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no-uid-stuff-on.mingw32.patch"

if [[ "${target}" == powerpc64le-* || "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fix-old-configure-macros.patch"
    autoreconf -vi
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()



# The products that we will ensure are always built
products = [
    LibraryProduct("libpopt", :libpopt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

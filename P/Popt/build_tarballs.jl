# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Popt"
version = v"1.19"

# Collection of sources required to complete build
sources = [
    # See <https://github.com/rpm-software-management/popt>
    ArchiveSource("https://ftp.osuosl.org/pub/rpm/popt/releases/popt-1.x/popt-1.19.tar.gz",
                  "c25a4838fc8e4c1c8aacb8bd620edb3084a3d63bf8987fdad3ca2758c63240f9"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
cd popt-*

if [[ $target = *-mingw32* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/get-w32-console-maxcols.mingw32.patch"
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no-uid-stuff-on.mingw32.patch"
fi

LIBS=
if [[ ${target} = *-musl* ]]; then
    LIBS='-liconv'
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static LIBS="${LIBS}"
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PTSCOTCH"
version = v"6.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.inria.fr/scotch/scotch/-/archive/v6.1.0/scotch-v6.1.0.tar.gz","4fe537f608f0fe39ec78807f90203f9cca1181deb16bfa93b7d4cd440e01bbd1"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scotch*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/native_build.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Makefile.patch"
if [[ "${target}" == *apple* || "${target}" == *freebsd* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/OSX_FreeBSD.patch"
fi
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Windows.patch"
fi
cd src
make ptscotch
cp ../lib/libpt* ${libdir}
cp ../include/p* ${includedir}
install_license ../LICENSE_en.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libptscotcherr", :libptscotcherr),
    LibraryProduct("libptscotcherrexit", :libptscotcherrexit),
    LibraryProduct("libptscotchparmetis", :libptscotchparmetis),
    LibraryProduct("libptscotch", :libptscotch, dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency("MPICH_jll"),
    Dependency("SCOTCH_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.6")

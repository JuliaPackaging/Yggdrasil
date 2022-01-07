# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCOTCH"
version = v"6.1.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.inria.fr/scotch/scotch/-/archive/v$(version)/scotch-v$(version).tar.gz","4e54f056199e6c23d46581d448fcfe2285987e5554a0aa527f7931684ef2809e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scotch*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/native_build.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Makefile.patch"
if [[ "${target}" == *apple* || "${target}" == *freebsd* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/OSX_FreeBSD.patch"
fi
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Windows.patch"
fi
cd src
make scotch
make esmumps
make prefix=$prefix install
install_license ../LICENSE_en.txt
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscotcherr", :libscotcherr),
    LibraryProduct("libscotcherrexit", :libscotcherrexit),
    LibraryProduct("libscotchmetis", :libscotchmetis),
    LibraryProduct("libscotch", :libscotch),
    LibraryProduct("libesmumps", :libesmumps)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.6")

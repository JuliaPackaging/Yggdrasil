# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "figtree"
version = v"0.9.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/figtree/files/figtree-$(version).zip", "f0b39cef8a0ab56075cce0c656b1b4327d9bd1acb31aad927241974ac4d10d82"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/figtree-*/
atomic_patch -p1 ../patches/fix-dlext.patch
make -j${nproc}
mkdir -p ${libdir}
mv "lib/libann_figtree_version.${dlext}" "${libdir}/libann_figtree_version.${dlext}"
mv "lib/libfigtree.${dlext}" "${libdir}/libfigtree.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libfigtree", :libfigtree),
    LibraryProduct("libann_figtree_version", :libann_figtree_version)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

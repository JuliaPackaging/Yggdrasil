# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "diffutils"
version_string = "3.10"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://ftp.gnu.org/gnu/diffutils/diffutils-$(version_string).tar.xz",
        "90e5e93cc724e4ebe12ede80df1634063c7a855692685919bfe60b556c9bd09e",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/diffutils-*/

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/win_sa_restart.patch
    atomic_patch -p1 ../patches/win_signal_handling.patch
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-dependency-tracking

# skip gnulib-tests on mingw
if [[ "${target}" == *-mingw* ]]; then
    make -j${nproc} SUBDIRS="lib src tests doc man po"
    make install SUBDIRS="lib src tests doc man po"
else
    make -j${nproc}
    make install
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("cmp", :_cmp)
    ExecutableProduct("diff", :_diff)
    ExecutableProduct("diff3", :diff3)
    ExecutableProduct("sdiff", :sdiff)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")

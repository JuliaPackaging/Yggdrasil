# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libcerf"
version = v"2.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://jugit.fz-juelich.de/mlz/libcerf/-/archive/v$(version.major).$(version.minor)/libcerf-v$(version.major).$(version.minor).tar.gz",
                  "b3a5e68a30bdbd3a58e9e7c038bd0aa2586b90bbb1c809f76665e176b2d42cdc"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcerf-*/
if [[ "${target}" == *-mingw* ]]; then
    # ref:  https://github.com/msys2/MINGW-packages/commit/b3e9553aa603dc446af4a0610187c23ac8c9d97f
    # fix wrong dll install path
    atomic_patch -p1 ../patches/001-fix-install-dest.patch

    # fix windows export symbols
    LDFLAGS+=" -Wl,--export-all-symbols"
    atomic_patch -p1 ../patches/002-fix-win-export.patch
fi

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcerf", :libcerf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tree_sitter_fortran"
version = v"0.5.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/stadelmanma/tree-sitter-fortran.git",
        "64e11001d7ef3e8ac18e55a3a2d811fe36430923"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tree-sitter-*

# Fix wide character function visibility (iswblank, etc.) on FreeBSD
atomic_patch -p1 $WORKSPACE/srcdir/patches/freebsd-wctype-visibility.patch

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build
cp -r queries ${prefix}/
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtree-sitter-fortran", :libtreesitter_fortran),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

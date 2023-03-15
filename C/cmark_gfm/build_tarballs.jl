# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cmark_gfm"
version = v"0.29.0" # 0.29.0.gfm.3

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/github/cmark-gfm.git", "cf7577d2f74289cb83de0a652afc1a8b08a37036"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cmark-gfm/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/extension_type_exports.patch
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcmark-gfm", :libcmark_gfm),
    LibraryProduct("libcmark-gfm-extensions", :libcmark_gfm_extensions),
    ExecutableProduct("cmark-gfm", :cmark_gfm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

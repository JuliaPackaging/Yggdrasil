# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libversion"
version = v"3.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/repology/libversion.git", "f851fec7d976820061952f6d90d3b60f2bae774b"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libversion/
atomic_patch -l -p1 ../cmake.patch
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_STANDARD=99 \
    -DCMAKE_C_EXTENSIONS=ON
cmake --build build
cmake --install build
install_license ${WORKSPACE}/srcdir/libversion/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libversion", :libversion),
    ExecutableProduct("version_sort", :version_sort),
    ExecutableProduct("version_compare", :version_compare)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

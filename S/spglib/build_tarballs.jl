# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "spglib"
version = v"1.16.1"

# Collection of sources required to build spglib
sources = [
    ArchiveSource("https://github.com/atztogo/spglib/archive/v$(version).tar.gz",
                  "e90682239e4ef63b492fa4e44f7dbcde2e2fe2e688579d96b01f2730dfdf5b2e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/spglib-*/
if [[ ${target} == *-mingw32 ]]; then
    sed -i -e 's/LIBRARY/RUNTIME/' CMakeLists.txt
fi
mkdir _build
cd _build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      ..
make -j${nproc}
make install VERBOSE=1
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsymspg", :libsymspg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

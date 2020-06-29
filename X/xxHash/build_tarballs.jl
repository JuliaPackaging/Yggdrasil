# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "xxHash"
version = v"0.7.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Cyan4973/xxHash/archive/v0.7.4.tar.gz", "4d9706c9da4fbdf901598f5e3b71db0eddd4ac962e827a73ebf75d66dfd820fe")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd $WORKSPACE/srcdir/xxHash-*/
mkdir build
cd build
cmake ../cmake_unofficial -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
CPPFLAGS=-DXXH_INLINE_ALL make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    cd "${prefix}/lib"
    ar x libxxhash.dll.a
    cc -shared -o "${libdir}/libxxhash.dll" *.o
    rm *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxxhash", :libxxhash)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

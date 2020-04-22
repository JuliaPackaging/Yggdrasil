# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bloaty"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/bloaty/releases/download/v1.0/bloaty-1.0.tar.bz2",
                  "e1cf9830ba6c455218fdb50e7a8554ff256da749878acfaf77c032140d7ddde0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bloaty*/
apk add protobuf
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install

# Remove extra stuff
rm ${bindir}/protoc*
rm ${libdir}/*.a
rm -r ${prefix}/include
rm -r ${prefix}/lib/cmake/
rm -r ${prefix}/lib/pkgconfig/
rm -rf ${prefix}/lib64/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis([p for p in supported_platforms() if !isa(p, Windows)])

# The products that we will ensure are always built
products = [
    ExecutableProduct("bloaty", :bloaty)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

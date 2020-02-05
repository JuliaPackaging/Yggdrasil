# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Chemfiles"
version = v"0.9.3"

# Collection of sources required to complete build
sources = [
    "https://github.com/chemfiles/chemfiles/archive/$version.tar.gz" =>
    "541878d189886dd52a247be711ab897fc6062c3275c34ee2e76a99b04132c74d",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/chemfiles-*/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libchemfiles", :libchemfiles)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

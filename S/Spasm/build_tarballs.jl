# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Spasm"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/laurentbartholdi/spasm.git", "072719a40c837e447dfe4ae9e4941c60d9a28eda"),
    GitSource("https://github.com/linbox-team/givaro.git", "fc6cac7820539c900dde332326c71461ba7b910b"),
    GitSource("https://github.com/linbox-team/fflas-ffpack.git", "94aa88263f5c6032adb5c86bf806f007fec7aded")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/givaro
./autogen.sh CCNAM=gcc --prefix=$prefix --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

cd ${WORKSPACE}/srcdir/fflas-ffpack
./autogen.sh PKG_CONFIG_PATH=$prefix/lib/pkgconfig --prefix=$prefix --build=${MACHTYPE} --host=${target}`)
make install

cd ${WORKSPACE}/srcdir/spasm
PKG_CONFIG_PATH=$prefix/lib/pkgconfig cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/spasm/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = [Platform("x86_64", "linux")] # for testing, for now

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    Dependency("GMP_jll", v"6")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

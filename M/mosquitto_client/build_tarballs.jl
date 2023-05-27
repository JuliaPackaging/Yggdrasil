# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mosquitto_client"
version = v"2.0.15"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eclipse/mosquitto.git", "dc75fec606d5c266cff5b3cf2259beee4523cda7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mosquitto/

# Fix "cannot finding openssl" under Windows
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64/
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DDOCUMENTATION=OFF \
    -DWITH_CJSON=OFF \
    -DWITH_BROKER=OFF \
    -DWITH_APPS=OFF \
    -DWITH_PLUGINS=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmosquitto", :libmosquitto)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

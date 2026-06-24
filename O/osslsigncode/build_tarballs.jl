# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "osslsigncode"
version = v"2.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mtrojnar/osslsigncode",
                  "76ee550c9d3b9f0e559f044e18136b74c167fef2"),
]

script = raw"""
    cd $WORKSPACE/srcdir/osslsigncode

    sed -i 's/Ws2_32/ws2_32/g' CMakeLists.txt

    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DZLIB_INCLUDE_DIR=${includedir} \
        -DZLIB_LIBRARY="${libdir}/libz.${dlext}"

    cmake --build build --parallel ${nproc}
    
    install_license LICENSE.txt
    install -Dvm 755 "build/osslsigncode${exeext}" "${bindir}/osslsigncode${exeext}"
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("osslsigncode", :osslsigncode)
]

dependencies = [
    Dependency("OpenSSL_jll", compat="3.0.16"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")

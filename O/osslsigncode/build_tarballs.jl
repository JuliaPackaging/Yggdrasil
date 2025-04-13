# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "osslsigncode"
version = v"2.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mtrojnar/osslsigncode",
                  "4568c890cc1538ca80be3ee36775ba42223dea04"),
]

script = raw"""
    if [[ "${target}" == *-mingw32 ]]; then
        cd /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/lib/
        ln -s libws2_32.a libWs2_32.a
    fi

    cd $WORKSPACE/srcdir/osslsigncode

    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DZLIB_INCLUDE_DIR=/workspace/destdir/include \
        -DZLIB_LIBRARY=/workspace/destdir/lib/libz.a

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
    Dependency("Zlib_jll", compat="1.3.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")

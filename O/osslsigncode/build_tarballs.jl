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

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("osslsigncode", :osslsigncode)
]

dependencies = [
    Dependency("OpenSSL_jll", compat="3.0.16"),
    Dependency("Zlib_jll", compat="1.3.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")

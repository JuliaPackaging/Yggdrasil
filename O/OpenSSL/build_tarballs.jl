using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"1.1.10" # <--- This version number is a lie to build for experimental platforms

sources = [
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1k.tar.gz",
                  "892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openssl-*/

# This build system does not like llvm-ranlib
if [[ ${target} == *darwin* ]]; then
    export RANLIB=/opt/${target}/bin/${target}-ranlib
fi

# Manual translation of BB $target to Configure-target, see `./Configure --help`
function translate_target()
{
    if [[ ${target} == x86_64-linux* ]]; then
        echo linux-x86_64
    elif [[ ${target} == i686-linux* ]]; then
        echo linux-x86
    elif [[ ${target} == arm-linux* ]]; then
        echo linux-armv4
    elif [[ ${target} == aarch64-linux* ]]; then
        echo linux-aarch64
    elif [[ ${target} == powerpc64le-linux* ]]; then
        echo linux-ppc64le
    elif [[ ${target} == x86_64-apple-darwin* ]]; then
        echo darwin64-x86_64-cc
    elif [[ ${target} == aarch64-apple-darwin* ]]; then
        echo darwin64-arm64-cc
    elif [[ ${target} == x86_64-unknown-freebsd* ]]; then
        echo BSD-x86_64
    elif [[ ${target} == x86_64*mingw* ]]; then
        echo mingw64
    elif [[ ${target} == i686*mingw* ]]; then
        echo mingw
    else
        if [[ ${nbits} == 32 ]]; then
            echo linux-generic32
        else
            echo linux-generic64
        fi
    fi
}

./Configure shared --prefix=$prefix $(translate_target)
make -j${nproc}
make install_sw
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built.  What are these naming conventions guys?  Seriously?!
products = [
    LibraryProduct(["libcrypto", "libcrypto-1_1", "libcrypto-1_1-x64"], :libcrypto),
    LibraryProduct(["libssl", "libssl-1_1", "libssl-1_1-x64"], :libssl),
    ExecutableProduct("openssl", :openssl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

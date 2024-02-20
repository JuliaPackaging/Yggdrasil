# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "VerizonEctoken"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/VerizonDigital/ectoken.git",
              "7b8812d476f5be5b290fe2832859b9b7636f43ae"),

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
export OPENSSL_INCLUDE="-I${includedir}"
export OPENSSL_LIBS="-lssl -lcrypto"
cd ectoken/c-ectoken/ecencrypt/
cc -m64 -O2 -Wall -Werror -std=gnu99 ec_encrypt.c ectoken_v3.c base64.c -o ${bindir}/ectoken3${exeext} $OPENSSL_LIBS $OPENSSL_INCLUDE -lm -lpthread -ldl
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc")
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("ectoken3", :ectoken3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

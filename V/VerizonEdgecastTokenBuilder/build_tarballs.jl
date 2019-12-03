# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "VerizonEdgecastTokenBuilder"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/VerizonDigital/ectoken.git" =>
    "7b8812d476f5be5b290fe2832859b9b7636f43ae",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
export OPENSSL_INCLUDE="-I $prefix/include"
export OPENSSL_LIBS="$prefix/lib/libssl.a $prefix/lib/libcrypto.a"
cd ectoken/c-ectoken/ecencrypt/
gcc -m64 -O2 -Wall -Werror -std=gnu99 ec_encrypt.c ectoken_v3.c base64.c -o 64/ectoken3 $OPENSSL_LIBS $OPENSSL_INCLUDE -lm -lpthread -ldl
cp 64/ectoken3 $prefix/bin/
exit

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("ectoken3", :ectoken3)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "PackageSpec(
  name = OpenSSL_jll
  uuid = 458c3c95-2e84-50aa-8efc-19380b2a3a95
  version = *
)",

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)


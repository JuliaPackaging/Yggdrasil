using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"3.0.15"

sources = [
    ArchiveSource("https://github.com/openssl/openssl/releases/download/openssl-$version/openssl-$version.tar.gz",
                  "23c666d0edf20f14249b3d8f0368acaee9ab585b09e1de82107c66e1f3ec9533"),
]

include("../common.jl")

# The products that we will ensure are always built.  What are these naming conventions guys?  Seriously?!
products = [
    LibraryProduct(["libcrypto", "libcrypto-3", "libcrypto-3-x64"], :libcrypto),
    LibraryProduct(["libssl", "libssl-3", "libssl-3-x64"], :libssl),
    ExecutableProduct("openssl", :openssl),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 4

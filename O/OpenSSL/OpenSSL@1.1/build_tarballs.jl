using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"1.1.22"

sources = [
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1v.tar.gz",
                  "d6697e2871e77238460402e9362d47d18382b15ef9f246aba6c7bd780d38a6b0"),
]

include("../common.jl")

# The products that we will ensure are always built.  What are these naming conventions guys?  Seriously?!
products = [
    LibraryProduct(["libcrypto", "libcrypto-1_1", "libcrypto-1_1-x64"], :libcrypto),
    LibraryProduct(["libssl", "libssl-1_1", "libssl-1_1-x64"], :libssl),
    ExecutableProduct("openssl", :openssl),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"1.1.20"

sources = [
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1t.tar.gz",
                  "8dee9b24bdb1dcbf0c3d1e9b02fb8f6bf22165e807f45adeb7c9677536859d3b"),
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

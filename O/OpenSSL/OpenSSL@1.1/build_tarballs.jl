using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"1.1.21"

sources = [
    ArchiveSource("https://www.openssl.org/source/openssl-1.1.1u.tar.gz",
                  "e2f8d84b523eecd06c7be7626830370300fbcc15386bf5142d72758f6963ebc6"),
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

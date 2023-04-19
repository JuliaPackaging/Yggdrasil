using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"3.0.8"

sources = [
    ArchiveSource("https://www.openssl.org/source/openssl-$version.tar.gz",
                  "6c13d2bf38fdf31eac3ce2a347073673f5d63263398f1f69d0df4a41253e4b3e"),
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

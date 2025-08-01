using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"3.5.1"

sources = [
    ArchiveSource("https://github.com/openssl/openssl/releases/download/openssl-$version/openssl-$version.tar.gz",
                  "529043b15cffa5f36077a4d0af83f3de399807181d607441d734196d889b641f"),
]

include("../common.jl")

# The products that we will ensure are always built.  What are these naming conventions guys?  Seriously?!
products = [
    LibraryProduct(["libcrypto", "libcrypto-3", "libcrypto-3-x64"], :libcrypto),
    LibraryProduct(["libssl", "libssl-3", "libssl-3-x64"], :libssl),
    ExecutableProduct("openssl", :openssl),
]

# Build the tarballs.
# We need GCC 6 for asm instructions on powerpc64le
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")

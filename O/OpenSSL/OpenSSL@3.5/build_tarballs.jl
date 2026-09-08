using BinaryBuilder

# Collection of sources required to build OpenSSL
name = "OpenSSL"
version = v"3.5.8"

sources = [
    ArchiveSource("https://github.com/openssl/openssl/releases/download/openssl-$version/openssl-$version.tar.gz",
                  "a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2"),
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

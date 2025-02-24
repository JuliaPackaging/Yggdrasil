using BinaryBuilder

# Collection of pre-build Bitwarden Secret Manager CLI binaries
name = "bitwarden_sdk_sm"
version = v"1.0.0"

url_prefix = "https://github.com/bitwarden/sdk-sm/releases/download/bws-v$(version)"
sources = [
    ArchiveSource("$(url_prefix)/bws-x86_64-unknown-linux-gnu-$(version).zip", "9077fb7b336a62abc8194728fea8753afad8b0baa3a18723fc05fc02fdb53568"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)/bws-aarch64-apple-darwin-$(version).zip", "5dd716878e5627220aa254cbe4e41e978f226f72d9117fc195046709db363e20"; unpack_target = "aarch64-apple-darwin"),
    ArchiveSource("$(url_prefix)/bws-x86_64-apple-darwin-$(version).zip", "7e06cbc0f3543dd68585a22bf1ce09eca1d413322aa22554a713cf97de60495a"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)/bws-aarch64-unknown-linux-gnu-$(version).zip", "20a3dcb9e3ce7716a1dc3c0e1c76cea9d5e2bf75094cbb5aad54ced4304929cb"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)/bws-x86_64-pc-windows-msvc-$(version).zip", "69b8d0fb2facc8cec4dd2b8157a3496ecaaa376ee1b0fd822012192ce7437505"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)/bws-aarch64-unknown-linux-gnu-$(version).zip", "20a3dcb9e3ce7716a1dc3c0e1c76cea9d5e2bf75094cbb5aad54ced4304929cb"; unpack_target = "aarch64-linux-gnu"),
    FileSource("https://raw.githubusercontent.com/bitwarden/sdk-sm/4518617715c7b4b3afd3700d129d6b535b2732ff/LICENSE", "81a78a0c6ee613b466974b74ac916573dd867c30ade85894a9d57f429600bef4")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install -Dvm 755 "${target}/bw${exeext}" -t "${bindir}"
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; cxxstring_abi="cxx11"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("aarch64", "linux"; cxxstring_abi="cxx11"),
    Platform("aarch64", "macos")
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("bws", :bws)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

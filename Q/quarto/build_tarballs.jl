using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.7.31"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "61149ee0c2dc2426aa0431b01e26313b100615c7a164b2150a45e34c4d1ecc57"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "0cec17c96ab8f3102a0d9863dfa828199f39cb0db5dbcb6e1385e0d05665af04"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "a247738c10a542e6b6a82cd3692bce114e7d4fc65194ffff0d1413613f530e47"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "a247738c10a542e6b6a82cd3692bce114e7d4fc65194ffff0d1413613f530e47"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win.zip", "ec4807b0b4bb675ddd35a41f7143da1e0d9c03b70e6f4fec4df9bde2e6b5ee89"; unpack_target="x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/v$(quarto_ver)/COPYRIGHT", "b99ec68b0ae2766380ecd177de507b799d1e3f6b7334d940a57021d3e4299721"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/v$(quarto_ver)/COPYING.md", "6b985ce085f33a39f96d12321cfbcee03aa2ad4249755f534537f38019dfa123"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
if [[ "${target}" == *-linux-* ]]; then
    subdir="quarto-*/"
fi
cp -r ${target}/${subdir}* ${prefix}
chmod -R +x ${bindir}
install_license COPYRIGHT
install_license COPYING.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("quarto", :quarto),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

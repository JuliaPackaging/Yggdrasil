using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.6.39"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "d797c796713a57c14d8115f49a45d626a16478697096a0421f2d2d980e5f9d4a"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "cb3cda3272b27841862370a897b883e85005ddae9b5e57ec13c10798d46ee0b6"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "5b422f396756ee0ee268970ae851775fed7e1005aea98500d59b7f12cd9a4e16"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "5b422f396756ee0ee268970ae851775fed7e1005aea98500d59b7f12cd9a4e16"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win.zip", "0fc0678222326ca5b2affc97df832dc23b71cb404dd9b17895db7a607e8e5a75"; unpack_target="x86_64-w64-mingw32"),
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

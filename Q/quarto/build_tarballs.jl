using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.8.24"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "6b83c1c9b6f2ce6454798b42260bd2ee184551d74debe817b8aaf28b09ac22d0"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "89a97a65a242a5b9b010a9f9978928c1d8e4ac02a558c9cd91a110c3f2611fdd"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "8f3be3719e8332c4583bd03aeb541b7c5aebc4f24c1799502c97051bbaa88c63"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "8f3be3719e8332c4583bd03aeb541b7c5aebc4f24c1799502c97051bbaa88c63"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win.zip", "5f9276b3ea25752b99d0071e6ad93701d381b7db3b7ec40a32421b5556f4d0ea"; unpack_target="x86_64-w64-mingw32"),
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

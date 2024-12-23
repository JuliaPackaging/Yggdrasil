using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.6.39"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "6418effd9f7c8a5f043197bcf1f30a4a2d588de399f23121ecec580ca5133296"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "13225b149fa487457ab633a73e4e8fad892aa4d1dc8e44a20d06e5b51995cdd6"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "0c90ca0ad03b4337213d71ec97b3fa5ed1e1fe450c4df64eb6c825808cc70e61"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "0c90ca0ad03b4337213d71ec97b3fa5ed1e1fe450c4df64eb6c825808cc70e61"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win.zip", "7e8c55c2151f4f898230f53451eac199206cd7b018308ab203e9b3353cacdf19"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/v$(quarto_ver)/COPYRIGHT", "490f3bfa035e325018ce9b0c8c2aec1f291c67ff55358a653d079488385af517"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/v$(quarto_ver)/COPYING.md", "54a55511991726b38e3867966ab14fd62919114670f2178654cced9394af78fd"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;julia_compat="1.6")

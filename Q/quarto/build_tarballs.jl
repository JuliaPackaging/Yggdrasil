using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.7.32"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "262505e3d26459c64e66efefd4b9240eb755ea20dd6fe876d6aa64c7a7b13d27"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "87835e6ed965d865ee1cda367ff0316c7d52104c114f5f1962fdc9fe5da46cd0"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "b49912bbe2b507f03d0bac9089f0e97437a87226c59a371e4eff8712557b16e8"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "b49912bbe2b507f03d0bac9089f0e97437a87226c59a371e4eff8712557b16e8"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win.zip", "956d5162377d0138c2d1972eb3aa6634b5369aa9286871a95f4f3989e673854a"; unpack_target="x86_64-w64-mingw32"),
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

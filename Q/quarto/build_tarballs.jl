using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.9.38"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "ea8c897368791ad9f200010c087ea3111b2e556b12a960487dd4e216902aa102"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "75fbc5c1121ffe65e564e9d24711db2ad8f617f9552f5dc7d8a06307d72dde38"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "47089a5020cfb41981ba0d4b46e110edfa608722aea45ef248e14efba6d6b18a"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos.tar.gz", "47089a5020cfb41981ba0d4b46e110edfa608722aea45ef248e14efba6d6b18a"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win.zip", "3dd3b22616dcae65f710b1d6c019b818027312c8cbf54a0a08fdd9842346375e"; unpack_target="x86_64-w64-mingw32"),
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

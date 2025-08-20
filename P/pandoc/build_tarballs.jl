using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "3.6.4"
version = VersionNumber(pandoc_ver)

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "5def6e1ff535e397becce292ee97767a947306150b9fb1488003b67ac3417c5e"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86_64-macOS.zip", "35789fb4afc61266b954035059820dd546b10d8f05fef36a8deadffaedffc2b8"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-arm64-macOS.zip", "88af17f1885afacb25f70ce4c8c44428feb6da860b6cf690e30da77998456c7f"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "a9e5feb3d56d2fb0e3e765d1c33b8ee6b72e6963d7de31504edeec8cd1be34b1"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "ad5cf63fe0420388d9ec513f02d03e061477b786d11a328164dce8ad7387b8bd"; unpack_target = "aarch64-linux-gnu"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/$(pandoc_ver)/COPYRIGHT", "e9dd2c20808f570f0fe3c06b36246711e253543ba4eda22c8cc934addd007b48"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/$(pandoc_ver)/COPYING.md", "e7ea3adeab955103a837b692ca0017cb3abbed0d3dccbfa499d6b2b825d698c3"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
if [[ "${target}" != *-mingw* ]]; then
    subdir="bin/"
fi
cp ${target}/pandoc-*/${subdir}pandoc${exeext} ${bindir}
chmod +x ${bindir}/*
install_license COPYRIGHT
install_license COPYING.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("aarch64", "linux"),
    Platform("aarch64", "macos"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pandoc", :pandoc),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

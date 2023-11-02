using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "3.1.9"
version = VersionNumber(pandoc_ver)

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "4d2ceae48a7fd49abb4e390988b0bb10999fbd47110f51af73755a35918d2c6c"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.zip", "302d278a7370b9a820aebcb54304d74d8f0f78ce565a7e465df5a6290c3e7968"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS.zip", "d3f79fc9ba4da848b76e9edfb874cd6bcce9430cf4a105c3646828405310d562"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "11eb6dbe5286c9e5edb0cca4412e7d99ec6578ec04158b0b7fe11f7fd96688e5"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "3932f1b07993cdae3bcfa7523a8eb19654269d2c30e4ec16d93c4211980fe27a"; unpack_target = "aarch64-linux-gnu"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/$(pandoc_ver)/COPYRIGHT", "bec2a2261d16b5ffddde7e7f2f51d2131a1686006f32a61475a4054415d7e367"),
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

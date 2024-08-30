using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "3.3"
version = VersionNumber(pandoc_ver)

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "0c97d03e85a65b366fb1ccd9db32a80c10eebae6e1dc36ee58458f5294d58556"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86_64-macOS.zip", "1a9bc70aaa306d3274f9d86d9a3a656ec1e366dc09f02fd1e8e0cab0ffbc0259"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-arm64-macOS.zip", "9f97774d6cd6a3510122fed6bcd05b060e17f5d2db5cf8edec4d96c670d5660d"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "05b47539f09c65fd94ce2a1741412805074ae764477267a2ff9c2cde8ea7fe8d"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "ae617cce1ba807453619c79122849afba4f558061056f9e1cc0da10189796443"; unpack_target = "aarch64-linux-gnu"),
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

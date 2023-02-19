using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "3.1"
version = VersionNumber(pandoc_ver)

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "37de6be90055d9a7e1b4e3384cd7fc4c42e138a77f62ddeec12f362bfa3ee18e"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.zip", "9eba0fa40cb21e12dbbb6876b195d51729273484b71d41979acb02f379da195b"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS.zip", "9eba0fa40cb21e12dbbb6876b195d51729273484b71d41979acb02f379da195b"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "21ef9294c91fb9e6bd106126d3ee67139510ea0f56256bb8d0376d97c9ab3d23"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "501d66de88c6e9d143e6631ded152ced7421bc32b6f16cadab18b2064916fe63"; unpack_target = "aarch64-linux-gnu"),
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

using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "2.19.2"
version = v"2.19.3"

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "9d55c7afb6a244e8a615451ed9cb02e6a6f187ad4d169c6d5a123fa74adb4830"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.zip", "af0cda69e31e42f01ba6adc0aa779d3e5853e6c092beeb420a4fc22712d2110b"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS.zip", "af0cda69e31e42f01ba6adc0aa779d3e5853e6c092beeb420a4fc22712d2110b"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "e7a0c92b4af6cad31d9899a8b92a3992e18634320349bbf56b729bbbcf71bb99"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "43f364915b9da64905fc3f6009f5542f224e54fb24f71043ef5154540f1a3983"; unpack_target = "aarch64-linux-gnu"),
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

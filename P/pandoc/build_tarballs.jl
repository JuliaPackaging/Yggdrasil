using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
version = v"2.11.4"
pandoc_ver = "2.11.4"

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "b15ce6009ab833fb51fc472bf8bb9683cd2bd7f8ac948f3ddeb6b8f9a366d69a"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.zip", "13b8597860afa6ab802993a684b340be3f31f4d2a06c50b6601f9e726cf76f71"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "ee1b0c4d0f539ee8316d6cebb29f6aa709aa3a72be2b2b4ab6e9e4a77a01a50b"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/54d8c6959cc53e78cfea2093b33504672f81ed74/COPYING.md", "2b0d4dda4bf8034e1506507a67f80f982131137afe62bf144d248f9faea31da4"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/54d8c6959cc53e78cfea2093b33504672f81ed74/COPYRIGHT", "39be98cc4d2906dd44abf8573ab91557e0b6d51f503d3a889dab0e8bcca1c43f"),
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
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pandoc", :pandoc),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

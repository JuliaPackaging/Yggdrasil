using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "3.13"
version = VersionNumber(pandoc_ver)

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "38aa33b325a2bc96a4c39409631212db55702f564250bcdbead180b3bf646389"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86_64-macOS.zip", "1823278715aa405aaf21b59cde5dc789346aa8d4fc307467f9a9ee84162bedc5"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-arm64-macOS.zip", "f436d18bebbfb3ddd326597686dacab9fac5dc23bd060495020f35a28a43a7c3"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "23e1f2e978a3df80db8bf65c9c59534f41a23140480cfb4f783a882ab7dc6a4e"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "21e1d4ba09bd0b334590d204580fd4f6629b21be4ab6a32b26cc98982e9e0c68"; unpack_target = "aarch64-linux-gnu"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/$(pandoc_ver)/COPYRIGHT", "842e33ef01625e93f85bebb8bac83aa570186b7aa77a09971257cc29f8f60740"),
    FileSource("https://raw.githubusercontent.com/jgm/pandoc/$(pandoc_ver)/COPYING.md", "3ebfbf9235b049d384cdba5a66a1a3434bb544391e720b76faa8e1b3ee61a4e5"),
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

using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc"
pandoc_ver = "3.10.1"
version = VersionNumber(pandoc_ver)

url_prefix = "https://github.com/jgm/pandoc/releases/download/$(pandoc_ver)/pandoc-$(pandoc_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "72948bf5784f560d5ad1876709daca27e0667f262da727bb33f77b58e52df2f5"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86_64-macOS.zip", "76430dd0ce5305fc4b91d8c0d5c22a00c8d2197ad3cef3937f65048f087164f7"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-arm64-macOS.zip", "8607160694a70ed9aa63776caa44acef3afb729c379c7c283724b7e27455bfda"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64.zip", "4725a1883e2171c2e181e6fd45003acb59ca4e9cbe031fdd3b79ef0d697d36aa"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "cd3963da375793a4804c65ae538b4f7b9c23f87cac7f6c74a1cf5e2fff7e8d59"; unpack_target = "aarch64-linux-gnu"),
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

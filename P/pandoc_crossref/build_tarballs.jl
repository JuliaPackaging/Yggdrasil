using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc-crossref"

# Actually, this should be v"0.3.6.4".
version = v"0.3.6"
crossref_ver = "0.3.6.4"

url_prefix = "https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.6.4/pandoc-crossref-"
sources = [
    ArchiveSource("$url_prefix-Linux-$crossref_ver.tar.xz", "57e8f71d46c401daf0a3247b7405b49503b836e93893730e6e5907f6cb2c0885"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$url_prefix-macOS-$crossref_ver.tar.xz", "b63ac830d7164279eb80041cd5f793e6b611ce1a701a86308ce5b2a3a99d33b2"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$url_prefix-Windows-$crossref_ver.tar.xz", "3e943fcdd3f91951fe18f9900e136ccb9ea810b2582f4bd929760357eaf83ef4"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/lierdakil/pandoc-crossref/65858c01a76f75990e7e30bcdb571cd84a69d47c/LICENSE", "39db8f9acf036595a2566ea3fe560bc7bd65d8749f088e0f4a4ef2f8a6cb4b34"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
if [[ "${target}" != *-mingw* ]]; then
    subdir="bin/"
fi
cp ${target}/pandoc-crossref/${subdir}pandoc-crossref${exeext} ${bindir}
chmod +x ${bindir}/pandoc-crossref
install_license LICENSE
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
    ExecutableProduct("pandoc-crossref", :pandoc_crossref),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

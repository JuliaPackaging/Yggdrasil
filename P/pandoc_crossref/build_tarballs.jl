using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc_crossref"

crossref_ver = "0.3.15.0"
version = v"0.3.15"

url_prefix = "https://github.com/lierdakil/pandoc-crossref/releases/download/v$(crossref_ver)/pandoc-crossref"
sources = [
    ArchiveSource("$(url_prefix)-Linux.tar.xz", "07951a4dd43ec221863b6ee8a3721c7354a07ecb1e6066fa405de522ec5987fd"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.tar.xz", "4ddadd2e6a5ed4abbbe1d58ac9ff235789615f6b4e69e8bc5f3dbe50ff3eda8b"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS.tar.xz", "4ddadd2e6a5ed4abbbe1d58ac9ff235789615f6b4e69e8bc5f3dbe50ff3eda8b"; unpack_target = "aarch64-apple-darwin20"),
    FileSource("$(url_prefix)-Windows.7z", "fcfa2be7f2a07875deb21a84fa1ec0b3399f23ad4758caf8d8e463663260fb9e"; filename = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/lierdakil/pandoc-crossref/v$(crossref_ver)/LICENSE", "39db8f9acf036595a2566ea3fe560bc7bd65d8749f088e0f4a4ef2f8a6cb4b34"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
dirprefix="${target}/"
if [[ "${target}" == *-mingw* ]]; then
    7z x "${target}"
    dirprefix=""
fi
install -m 755 "${dirprefix}pandoc-crossref${exeext}" "${bindir}/pandoc-crossref${exeext}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("aarch64", "macos"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pandoc-crossref", :pandoc_crossref),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("p7zip_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

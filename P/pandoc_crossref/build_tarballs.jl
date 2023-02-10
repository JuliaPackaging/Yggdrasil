using BinaryBuilder

# Collection of pre-build pandoc binaries
name = "pandoc_crossref"

crossref_ver = "0.3.14.0"
version = v"0.3.14"

url_prefix = "https://github.com/lierdakil/pandoc-crossref/releases/download/v$(crossref_ver)/pandoc-crossref"
sources = [
    ArchiveSource("$(url_prefix)-Linux.tar.xz", "9ad4aff57d58198b9d97fef71319c5b060ebcfc570055d87aa95b4117b40db56"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.tar.xz", "b29ebe076ecd462bf567f7d0774f70177aa109999a3c0fa542a6c3564ad50e2f"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS.tar.xz", "b29ebe076ecd462bf567f7d0774f70177aa109999a3c0fa542a6c3564ad50e2f"; unpack_target = "aarch64-apple-darwin20"),
    FileSource("$(url_prefix)-Windows.7z", "f07e7e64e7a2260d43e93941387aa320914f3e161697bce305622d4250040cb3"; filename = "x86_64-w64-mingw32"),
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

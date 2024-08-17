using BinaryBuilder
using Pkg: PackageSpec

include("utils.jl")

# Collection of pre-build pandoc binaries
name = "pandoc_crossref"

crossref_ver = "0.3.17.1c"
panddoc_jll_version = v"3.3.0"
version = pandoc_crossref_jll_version(crossref_ver)

url_prefix = "https://github.com/lierdakil/pandoc-crossref/releases/download/v$(crossref_ver)/pandoc-crossref"
sources = [
    ArchiveSource("$(url_prefix)-Linux.tar.xz", "0dc7aca677f4ec50419b53933ebe71ff86df6ac04d6108cd9913758cf8e118aa"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.tar.xz", "147a02f00a2d96366ea44c35dea996ed225735d293b655533bbc91c6bf4ce6de"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS.tar.xz", "147a02f00a2d96366ea44c35dea996ed225735d293b655533bbc91c6bf4ce6de"; unpack_target = "aarch64-apple-darwin20"),
    FileSource("$(url_prefix)-Windows.7z", "d9198fd48ebf0d098e72db7e09f0d88c796e281bf2abacfd1eb202c0ac1bbd18"; filename = "x86_64-w64-mingw32"),
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

    # Each `pandoc-crossref` release is built with a specific pandoc version and using
    # another version can be problematic. In order to avoid compatibility issues we specify
    # the exact version which `pandoc-crossref` was built with.
    #
    # TODO: Should actually be a `RuntimeDependency`:
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1330
    Dependency(PackageSpec(name="pandoc_jll"), compat="=$panddoc_jll_version"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

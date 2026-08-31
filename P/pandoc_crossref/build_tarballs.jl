using BinaryBuilder
using Pkg: PackageSpec

include("utils.jl")

# Collection of pre-build pandoc binaries
name = "pandoc_crossref"

crossref_ver = "0.3.25"
panddoc_jll_version = v"3.10.1"
version = pandoc_crossref_jll_version(crossref_ver)

url_prefix = "https://github.com/lierdakil/pandoc-crossref/releases/download/v$(crossref_ver)/pandoc-crossref"
sources = [
    ArchiveSource("$(url_prefix)-Linux-x64.tar.xz", "2319816e3545ee78e44e4a97c2174c72eedf4b51d436b32721b48f43458eb0f6"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-Linux-arm64.tar.xz", "5e4901a0f125145f2b9e1851a6a385ee60c3fd8bd6222115ac7d632a9c8130a2"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS-x64.tar.xz", "8db67222ec4c2b7a591e90d9d2d21ac2ba638b104a7a1f284c6d16623049c1c7"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macOS-arm64.tar.xz", "dddc2b730001733ef7c1bb6177639b3bf3ffb773a4385e8a9c402331522a4bb2"; unpack_target = "aarch64-apple-darwin20"),
    FileSource("$(url_prefix)-Windows-x64.7z", "61ad4ef235bd8b23d2f6ad84bfc74e9bac431de2f86d4b764d3b78dfe08f6cf4"; filename = "x86_64-w64-mingw32"),
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
    Dependency(PackageSpec(name="pandoc_jll"), compat="$panddoc_jll_version"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

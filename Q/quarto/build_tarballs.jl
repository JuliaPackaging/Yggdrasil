using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.4.549"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "61e03d40a75a4b32ad823c9b573db6228a58202a9b95f94d13c9cdf23dd7af78"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.tar.gz", "4d31524deddef13213e5c1fa89ef6d63ab10cc88e51f8daf180ec8e1dba159c4"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-win.zip", "c79fbff6e91ef77e439148a08d343beeee415c60c6c7fb498f3aa8633d176159"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/v$(quarto_ver)/COPYRIGHT", "490f3bfa035e325018ce9b0c8c2aec1f291c67ff55358a653d079488385af517"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/v$(quarto_ver)/COPYING.md", "54a55511991726b38e3867966ab14fd62919114670f2178654cced9394af78fd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
if [[ "${target}" == *-linux-* ]]; then
    subdir="quarto-*/"
fi
cp -r ${target}/${subdir}* ${prefix}
chmod -R +x ${bindir}
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
    ExecutableProduct("quarto", :quarto),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;julia_compat="1.6")

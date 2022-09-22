using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "quarto"
quarto_ver = "1.1.251"
version = VersionNumber(quarto_ver)

url_prefix = "https://github.com/quarto-dev/quarto-cli/releases/download/v$(quarto_ver)/quarto-$(quarto_ver)"
sources = [
    ArchiveSource("$(url_prefix)-linux-amd64.tar.gz", "544614108e31cd03d79724db0938405b69e904264d3c3279c767169e4373ed11"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macOS.tar.gz", "04a9f82fc5c66e87b7b64afe7c775c8b4977e0e6323e03c29adbd16918640a6f"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-win.zip", "57efeacbf6cdbaff66715bad50e2d10566381731ebeb905e5d4a896ab9f9f093"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/main/COPYRIGHT", "72e9878c027de95ff489de1ee25933176070a2f6f29c5c8ac613f6f16d72ffee"),
    FileSource("https://raw.githubusercontent.com/quarto-dev/quarto-cli/main/COPYING.md", "2b7f990a2f8f094afbf8b51011737588acc3acc63e5c436cac3d1a7a25a6773f"),
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

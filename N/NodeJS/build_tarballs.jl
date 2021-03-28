using BinaryBuilder

name = "NodeJS"
version = v"14.16.0"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "7212031d7468718d7c8f5e1766380daaabe09d54611675338e7a88a97c3e31b6"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "2b78771550f8a3e6e990d8e60e9ade82c7a9e2738b6222e92198bcd5ea857ea6"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "2339b4b1a8db39348cb1877b0cfdee3b2ef2b730f461ef7263610cbaaea5232a"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "14ec767e376d1e2e668f997065926c5c0086ec46516d1d45918af8ae05bd4583"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-win-x64.zip", "716045c2f16ea10ca97bd04cf2e5ef865f9c4d6d677a9bc25e2ea522b594af4f"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "9699067581e0d333b13158d4ebb27b6357444564548aaa220d821cdc6d840bd2"; unpack_target = "i686-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
cp -r ${target}/*/* ${prefix}/.
if [[ "${target}" == *-mingw* ]]; then
    chmod +x ${prefix}/{node.exe,npm,npx}
fi
install_license ${prefix}/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("powerpc64le", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("node", :node),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

using BinaryBuilder

name = "NodeJS_16"
version = v"16.0.0"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "9268cdb3c71cec4f3dc3bef98994f310c3bef259fae8c68e3f1c605c5dfcbc58"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "22e7d326b21195c4a0df92a7af7cfdf1743cd46fcc50e335e4086a1c1f2a9a13"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "bc28902e8e1453531bb38001cf705dff2456cdf5b856a37dac2f2d3d771b02c1"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "b00457dd7da6cc00d0248dc57b4ddd01a71eed6009ddadd8c854678232091dfb"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "2d6d412abcf7c9375f19fde14086a6423e5bb9415eeca1ccad49638ffc476ea3"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win-x64.zip", "99c2b01afb8d966fc876ec30ac7dfdbd9da9b17a3daeda92c19ce657ab9bea61"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "0600dffb5331b6f49e6ff4fa97770811746e0e2ecaf53de6deaafff277a644b4"; unpack_target = "i686-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
cp -r ${target}/*/* ${prefix}/.
cd ${prefix}
if [[ "${target}" == *-mingw* ]]; then
    mkdir bin
    chmod +x {node.exe,npm,npm.cmd,npx,npx.cmd}
    mv {node.exe,npm,npm.cmd,npx,npx.cmd} bin
    mv node_modules bin
fi
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("powerpc64le", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("node", :node),
    FileProduct("bin/npm", :npm),
    FileProduct("bin/npx", :npx),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.6")

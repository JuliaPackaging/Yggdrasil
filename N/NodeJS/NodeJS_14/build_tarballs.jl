using BinaryBuilder

name = "NodeJS_14"
version = v"14.16.1"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "068400cb9f53d195444b9260fd106f7be83af62bb187932656b68166a2f87f44"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "58cb307666ed4aa751757577a563b8a1e5d4ee73a9fac2b495e5c463682a07d1"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "de6ccb9bf08520939cc2ae0507634015981604b5eb6912d031d4b7fe146f0de4"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "54efe997dbeff971b1e39c8eb910566ecb68cfd6140a6b5c738265d4b5842d24"; unpack_target = "armv7l-linux-gnueabihf"),

    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "068400cb9f53d195444b9260fd106f7be83af62bb187932656b68166a2f87f44"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "58cb307666ed4aa751757577a563b8a1e5d4ee73a9fac2b495e5c463682a07d1"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "54efe997dbeff971b1e39c8eb910566ecb68cfd6140a6b5c738265d4b5842d24"; unpack_target = "armv7l-linux-musleabihf"),

    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "b762b72fc149629b7e394ea9b75a093cad709a9f2f71480942945d8da0fc1218"; unpack_target = "x86_64-apple-darwin14"),

    ArchiveSource("$(url_prefix)-win-x64.zip", "e469db37b4df74627842d809566c651042d86f0e6006688f0f5fe3532c6dfa41"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "cfb3535a172fb792a63814deffde405466902359bedfbd884188f6fc56f97d64"; unpack_target = "i686-w64-mingw32"),
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
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),

    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl")

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

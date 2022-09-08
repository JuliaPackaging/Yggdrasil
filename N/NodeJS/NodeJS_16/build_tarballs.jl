using BinaryBuilder

name = "NodeJS_16"
version = v"16.15.0"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "d1c1de461be10bfd9c70ebae47330fb1b4ab0a98ad730823fb1340e34993edee"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "2aa387e6a57ade663849efdc4fabf7431a38d975db98dcc79293840e6894d28b"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "625bf1f6cc2d608c51fc5b412ca162251871d14eb795cb006107d743c1da200c"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "3b54c8f57a8ab211b5e969cdf6d20b3bcd7f30f7e0444e00c409f78b90486d30"; unpack_target = "arm-linux-gnueabihf"),

    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "d1c1de461be10bfd9c70ebae47330fb1b4ab0a98ad730823fb1340e34993edee"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "2aa387e6a57ade663849efdc4fabf7431a38d975db98dcc79293840e6894d28b"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "3b54c8f57a8ab211b5e969cdf6d20b3bcd7f30f7e0444e00c409f78b90486d30"; unpack_target = "arm-linux-musleabihf"),
    
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "a6bb12bbf979d32137598e49d56d61bcddf8a8596c3442b44a9b3ace58dd4de8"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "ad8d8fc5330ef47788f509c2af398c8060bb59acbe914070d0df684cd2d8d39b"; unpack_target = "aarch64-apple-darwin20"),

    ArchiveSource("$(url_prefix)-win-x64.zip", "dbe04e92b264468f2e4911bc901ed5bfbec35e0b27b24f0d29eff4c25e428604"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "0d11a3844dad4ab679502495a4aa41041168a2caa81b8da9c7b5a14902c46986"; unpack_target = "i686-w64-mingw32"),
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
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("powerpc64le", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("armv7l", "linux"; libc="glibc", cxxstring_abi="cxx11"),

    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("armv7l", "linux"; libc="musl", cxxstring_abi="cxx11"),

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

using BinaryBuilder

name = "NodeJS_16"
version = v"16.20.2"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    # glibc linux
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz",    "c9193e6c414891694759febe846f4f023bf48410a6924a8b1520c46565859665"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz",  "b6945fcc9ad220386bb814bfae7137189fd17297f2959a744105e1bee006035a"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz","731d9ecc82ff59449566bf73959b16cc368b1060212b51d03edf3ec5e9937ced"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "88ea2ddef7db491d2e93c150d27fbec422a4d06d7a63bf34d46e6d20d30eed43"; unpack_target = "arm-linux-gnueabihf"),

    # musl linux (using same upstream linux tarballs)
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz",    "c9193e6c414891694759febe846f4f023bf48410a6924a8b1520c46565859665"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz",  "b6945fcc9ad220386bb814bfae7137189fd17297f2959a744105e1bee006035a"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "88ea2ddef7db491d2e93c150d27fbec422a4d06d7a63bf34d46e6d20d30eed43"; unpack_target = "arm-linux-musleabihf"),
    
    # macOS
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz",   "d7a46eaf2b57ffddeda16ece0d887feb2e31a91ad33f8774da553da0249dc4a6"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "6a5c4108475871362d742b988566f3fe307f6a67ce14634eb3fbceb4f9eea88c"; unpack_target = "aarch64-apple-darwin20"),

    # Windows
    ArchiveSource("$(url_prefix)-win-x64.zip", "f8bb35f6c08dc7bf14ac753509c06ed1a7ebf5b390cd3fbdc8f8c1aedd020ec3"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "c9c0b774328374973d5af5d72c4c6ce3932a1988c7efd32d84c35ba4771df41a"; unpack_target = "i686-w64-mingw32"),
]

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
    Platform("i686",  "windows"),
]

products = [
    ExecutableProduct("node", :node),
    FileProduct("bin/npm", :npm),
    FileProduct("bin/npx", :npx),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")

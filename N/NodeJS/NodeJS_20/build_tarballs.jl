using BinaryBuilder

name = "NodeJS_20"
version = v"20.11.1"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "bf3a779bef19452da90fb88358ec2c57e0d2f882839b20dc6afc297b6aafc0d7"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "e34ab2fc2726b4abd896bcbff0250e9b2da737cbd9d24267518a802ed0606f3b"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "9823305ac3a66925a9b61d8032f6bbb4c3e33c28e7f957ebb27e49732feffb23"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "e42791f76ece283c7a4b97fbf716da72c5128c54a9779f10f03ae74a4bcfb8f6"; unpack_target = "arm-linux-gnueabihf"),
    
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "bf3a779bef19452da90fb88358ec2c57e0d2f882839b20dc6afc297b6aafc0d7"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "e34ab2fc2726b4abd896bcbff0250e9b2da737cbd9d24267518a802ed0606f3b"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "e42791f76ece283c7a4b97fbf716da72c5128c54a9779f10f03ae74a4bcfb8f6"; unpack_target = "arm-linux-musleabihf"),
    
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "c52e7fb0709dbe63a4cbe08ac8af3479188692937a7bd8e776e0eedfa33bb848"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "e0065c61f340e85106a99c4b54746c5cee09d59b08c5712f67f99e92aa44995d"; unpack_target = "aarch64-apple-darwin20"),
    
    ArchiveSource("$(url_prefix)-win-x64.zip", "bc032628d77d206ffa7f133518a6225a9c5d6d9210ead30d67e294ff37044bda"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "b98e95f78416d1359b647cfa09ba2a48b76d41b56a776df822bf36ffe8e76a2d"; unpack_target = "i686-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
cp -r ${target}/*/* ${prefix}/.
cd ${prefix}
if [[ "${target}" == *-mingw* ]]; then
    for file in node.exe npm npm.cmd npx npx.cmd; do
        install -Dvm 0755 "${file}" "${bindir}/${file}"
    done
    mv node_modules "${bindir}/."
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
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.6")

using BinaryBuilder

name = "NodeJS_18"
version = v"18.16.0"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "fc83046a93d2189d919005a348db3b2372b598a145d84eb9781a3a4b0f032e95"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "dc3dfaee899ed21682e47eaf15525f85aff29013c392490e9b25219cd95b1c35"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "b4e66dcda5ba4a3697be3fded122dabb6a677deee3d7f4d3c7c13ebb5a13844c"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "a3968db44e5ae17243d126ff79b1756016b198f7cc94c6fad8522aac481b4ff3"; unpack_target = "arm-linux-gnueabihf"),

    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "fc83046a93d2189d919005a348db3b2372b598a145d84eb9781a3a4b0f032e95"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "dc3dfaee899ed21682e47eaf15525f85aff29013c392490e9b25219cd95b1c35"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "a3968db44e5ae17243d126ff79b1756016b198f7cc94c6fad8522aac481b4ff3"; unpack_target = "arm-linux-musleabihf"),
    
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "cd520da6e2e89fab881c66a3e9aff02cb0d61d68104b1d6a571dd71bef920870"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "82c7bb4869419ce7338669e6739a786dfc7e72f276ffbed663f85ffc905dcdb4"; unpack_target = "aarch64-apple-darwin20"),

    ArchiveSource("$(url_prefix)-win-x64.zip", "4b3bd4cb5570cc217490639e93a7e1b7a7a341981366661e514ce61941824a85"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "2a7e0fb22e1a36144ee8183c80ef2705cd9754c1d894f94bb6c94a681de47924"; unpack_target = "i686-w64-mingw32"),
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
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.6")

using BinaryBuilder

name = "NodeJS_18"
version = v"18.16.1"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "59582f51570d0857de6333620323bdeee5ae36107318f86ce5eca24747cabf5b"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "555b5c521e068acc976e672978ba0f5b1a0c030192b50639384c88143f4460bc"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "4c4928f8b1b01c2a93ebf0eba2e179c63e97bca103339dc4152405531ca5c738"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "ffac5b7627b086b16376751b641cb5c429f94cedf9a5f0f6cfc3cbe7aa0e6b89"; unpack_target = "arm-linux-gnueabihf"),

    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "59582f51570d0857de6333620323bdeee5ae36107318f86ce5eca24747cabf5b"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "555b5c521e068acc976e672978ba0f5b1a0c030192b50639384c88143f4460bc"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "ffac5b7627b086b16376751b641cb5c429f94cedf9a5f0f6cfc3cbe7aa0e6b89"; unpack_target = "arm-linux-musleabihf"),
    
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "3040210287a0b8d05af49f57de191afa783e497abbb10c340bae9158cb51fdd4"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "2ccb24e9211f4d17d8d8cfc0ea521198bb6a54e2f779f8feda952dbd3bb651ac"; unpack_target = "aarch64-apple-darwin20"),

    ArchiveSource("$(url_prefix)-win-x64.zip", "145bd2f79eaa50b76559bd78266f4585e57b88dbb94613698a9514a601f84e7f"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "950022d45729588421a535df7075c0b48fea26c41b66d545a300b2db67d949dc"; unpack_target = "i686-w64-mingw32"),
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

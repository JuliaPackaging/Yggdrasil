using BinaryBuilder

name = "NodeJS_22"
version = v"22.15.0"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "29d1c60c5b64ccdb0bc4e5495135e68e08a872e0ae91f45d9ec34fc135a17981"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "c3582722db988ed1eaefd590b877b86aaace65f68746726c1f8c79d26e5cc7de"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "a744107732546a3b112630cde1cc2db681559668cea36bee851348ed036c101c"; unpack_target = "powerpc64le-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "639a3ee3217049ba20e6f05651c7281a9d007111196387eb177081af8851e52f"; unpack_target = "arm-linux-gnueabihf"),
    
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "29d1c60c5b64ccdb0bc4e5495135e68e08a872e0ae91f45d9ec34fc135a17981"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "c3582722db988ed1eaefd590b877b86aaace65f68746726c1f8c79d26e5cc7de"; unpack_target = "aarch64-linux-musl"),
    ArchiveSource("$(url_prefix)-linux-armv7l.tar.gz", "639a3ee3217049ba20e6f05651c7281a9d007111196387eb177081af8851e52f"; unpack_target = "arm-linux-musleabihf"),
    
    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "f7f42bee60d602783d3a842f0a02a2ecd9cb9d7f6f3088686c79295b0222facf"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "92eb58f54d172ed9dee320b8450f1390db629d4262c936d5c074b25a110fed02"; unpack_target = "aarch64-apple-darwin20"),
    
    ArchiveSource("$(url_prefix)-win-x64.zip", "06067d4f0d463f90ed803d5eca5b039a05dec5d70fc7b7cc254803a59bd0e27c"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-win-x86.zip", "961e362568b91340b0229d27a64e3925ce5d807898a86074d61cab578f151843"; unpack_target = "i686-w64-mingw32"),
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

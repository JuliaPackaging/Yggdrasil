using BinaryBuilder

name = "NodeJS_24"
version = v"24.18.0"

url_prefix = "https://nodejs.org/dist/v$version/node-v$version"
unofficial_url_prefix = "https://unofficial-builds.nodejs.org/download/release/v$version/node-v$version"
sources = [
    ArchiveSource("$(url_prefix)-linux-x64.tar.gz", "783130984963db7ba9cbd01089eaf2c2efb055c7c1693c943174b967b3050cb8"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-arm64.tar.gz", "6b4484c2190274175df9aa8f28e2d758a819cb1c1fe6ab481e2f95b463ab8508"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-ppc64le.tar.gz", "fe1338972f79283c6bc21e61dbf4576bbe8c05aded2999d41c8643ad30265142"; unpack_target = "powerpc64le-linux-gnu"),

    ArchiveSource("$(unofficial_url_prefix)-linux-x64-musl.tar.gz", "ea58409911e141ec6b19d9178efa2d9185a13295005b1cbf5521b3157eed1d95"; unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(unofficial_url_prefix)-linux-arm64-musl.tar.gz", "b1c6c2dc31b46dd8fb2322f4fe75b07e775c5120bc37251deeea28f529d4567b"; unpack_target = "aarch64-linux-musl"),

    ArchiveSource("$(url_prefix)-darwin-x64.tar.gz", "dfd0dbd3e721503434df7b7205e719f61b3a3a31b2bcf9729b8b91fea240f080"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-darwin-arm64.tar.gz", "e1a97e14c99c803e96c7339403282ea05a499c32f8d83defe9ef5ec66f979ed1"; unpack_target = "aarch64-apple-darwin20"),

    ArchiveSource("$(url_prefix)-win-x64.zip", "0ae68406b42d7725661da979b1403ec9926da205c6770827f33aac9d8f26e821"; unpack_target = "x86_64-w64-mingw32"),
]

# Repackage Node's published binaries into the standard JLL layout. The musl
# archives come from the Node.js project's community-maintained builds.
script = raw"""
cd ${WORKSPACE}/srcdir/
cp -vr ${target}/*/* ${prefix}/.
cd ${prefix}
if [[ "${target}" == *-mingw* ]]; then
    for file in node.exe npm npm.cmd npx npx.cmd; do
        install -Dvm 0755 "${file}" "${bindir}/${file}"
    done
    mv -v node_modules "${bindir}/."
fi
install_license LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("powerpc64le", "linux"; libc="glibc", cxxstring_abi="cxx11"),

    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
    Platform("aarch64", "linux"; libc="musl", cxxstring_abi="cxx11"),

    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),

    Platform("x86_64", "windows"),
]

products = [
    ExecutableProduct("node", :node),
    FileProduct("bin/npm", :npm),
    FileProduct("bin/npx", :npx),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")

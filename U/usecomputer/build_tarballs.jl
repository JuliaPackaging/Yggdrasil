using BinaryBuilder, Pkg

name = "usecomputer"
version = v"0.1.9"

url_prefix = "https://github.com/remorses/usecomputer/releases/download/v$(version)"
sources = [
    ArchiveSource("$(url_prefix)/usecomputer-v$(version)-darwin-arm64.tar.gz",
        "f48472ce934e6e563575bda2614ed3c1bff6db5c383ab2a64a816bbb0c43f1c4";
        unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)/usecomputer-v$(version)-darwin-x64.tar.gz",
        "813b3482ed098690a87eb8047d65be0fc1b06a02243d37edb474f2ee39d1681f";
        unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)/usecomputer-v$(version)-linux-arm64.tar.gz",
        "0b2bff41fde2ce0b3a73acc7e4b451c6587a960c35c9806318878430a3b96fd2";
        unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)/usecomputer-v$(version)-linux-x64.tar.gz",
        "380bf752722276d844bdfdbbef6bf82c7221e2e74ea224ab92809dbb88102b61";
        unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)/usecomputer-v$(version)-win32-x64.zip",
        "0fe023bc412bb4928a57a50cdda06c36076bb7d7aea24da8bfcb1aa26bcef9ab";
        unpack_target = "x86_64-w64-mingw32"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/${target}/

mkdir -p ${libdir} ${includedir}
cp -v *usecomputer_c.${dlext} ${libdir}/
cp -v usecomputer.h ${includedir}/
install_license ${WORKSPACE}/srcdir/LICENSE
"""

platforms = [
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "linux"),
    Platform("x86_64", "windows"),
]

products = [
    LibraryProduct(["libusecomputer_c", "usecomputer_c"], :libusecomputer_c),
    FileProduct("include/usecomputer.h", :usecomputer_h),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")

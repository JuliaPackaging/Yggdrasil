using BinaryBuilder, Pkg

name = "biber"
biber_version = "2.19"
version = VersionNumber(biber_version)

url_prefix = "https://mirrors.ctan.org/biblio/biber/biber" 
url_infix = "biber-$(biber_version)"

sources = [
    ArchiveSource("$(url_prefix)-macos/$(url_infix)-darwin_universal.tar.gz", "0ebda145064eb5b8901a4ed5c8c5e5e6a5208e0aba425f7febcb5fb5b1a9c11b", unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-macos/$(url_infix)-darwinlegacy_x86_64.tar.gz", "af7b8a87fb6415b927d0fd645435e89af6ce58ea660d46fa8639918e2cb2cb17", unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-windows/$(url_infix)-MSWIN32.zip", "c1a731bf2361720728fc1875c19002ff01131ea0e003137dee348934e1f62d2f", unpack_target = "i686-w64-mingw32"),
    ArchiveSource("$(url_prefix)-windows/$(url_infix)-MSWIN64.zip", "f0bccdec320e89a04b067f1189957b4bbe6feb445005357601f6e295e83e97da", unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-linux/$(url_infix)-linux_x86_32.tar.gz", "d1f13cec63a109b39c1c03e6b81943a7526b0e692d81b4cd383073f155c6a68f", unpack_target = "i686-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux/$(url_infix)-linux_x86_64.tar.gz", "e2eda3e6ea7ac7e78d60e99a0e2aeb1096829f95791c06b768ed31a12889e58e", unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-aarch64/$(url_infix)-linux_aarch64.tar.gz", "fee859a192bf8fe53f7f5aa6067d54b3713ba46b647ea3c5f78db6a3bc060ff7", unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-musl/$(url_infix)-1-linux-musl_x86_64.tar.gz", "87ecc68fcdf0a3d60a8c03d2080d923a9f67d26f8db3f707784e2d45dd3694ab", unpack_target = "x86_64-linux-musl"),
    ArchiveSource("$(url_prefix)-freebsd/$(url_infix)-freebsd_amd64.tar.gz", "2641f50928a21d278b737d4862e74938512d69609a3428411de0621923b339c4", unpack_target = "x86_64-unknown-freebsd13.4"),
    FileSource("https://raw.githubusercontent.com/plk/biber/v$(biber_version)/LICENSE", "40f4a14f946367c05e2b009c5c1ae093ad2fbf4eb43929a12f23bf53d1806af6")
]

# All binaries from CTAN.ORG (SourceForge doesn't play well with BinaryBuilder.jl)
# https://mirrors.ctan.org/biblio/biber/biber-macos/biber-2.19-darwin_universal.tar.gz
# https://mirrors.ctan.org/biblio/biber/biber-macos/biber-2.19-darwinlegacy_x86_64.tar.gz
# https://mirrors.ctan.org/biblio/biber/biber-windows/biber-2.19-MSWIN32.zip
# https://mirrors.ctan.org/biblio/biber/biber-windows/biber-2.19-MSWIN64.zip
# https://mirrors.ctan.org/biblio/biber/biber-linux/biber-2.19-linux_x86_32.tar.gz
# https://mirrors.ctan.org/biblio/biber/biber-linux/biber-2.19-linux_x86_64.tar.gz
# https://mirrors.ctan.org/biblio/biber/biber-linux-aarch64/biber-2.19-linux_aarch64.tar.gz
# https://mirrors.ctan.org/biblio/biber/biber-linux-musl/biber-2.19-1-linux-musl_x86_64.tar.gz
# https://mirrors.ctan.org/biblio/biber/biber-freebsd/biber-2.19-freebsd_amd64.tar.gz

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install -Dvm 755 "${target}/biber${exeext}" "${bindir}/biber${exeext}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "freebsd"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("biber", :biber),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

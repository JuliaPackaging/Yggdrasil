using BinaryBuilder

name = "Tokei"
version = v"12.1.2"

sources = [
    ArchiveSource("https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-x86_64-apple-darwin.tar.gz", "2af8abb6a08b0513f9d16ca2c7cd37949b858d2a3e3227be8cc412b3b4937d5b"; unpack_target="x86_64-apple-darwin14-tokei-dir"),
    ArchiveSource("https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-x86_64-unknown-linux-gnu.tar.gz", "c8c5c4ab9e1ff47e745de70f4af3214078657399fa7a0da0b5f209d780e49978"; unpack_target="x86_64-linux-gnu-tokei-dir"),
    ArchiveSource("https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-x86_64-unknown-linux-musl.tar.gz", "331e77046935d655dce8d97ebb943fcc7e9684586dadf3d197f3df5e760cd31b"; unpack_target="x86_64-linux-musl-tokei-dir"),
    FileSource("https://github.com/XAMPPRocky/tokei/releases/download/v12.1.2/tokei-x86_64-pc-windows-msvc.exe", "b1d6c4b18f5fa238bd2c6e47caa65a7a3e4a1bd0de6df0b7c19c8083c941f57b"; filename="x86_64-w64-mingw32-tokei"),
    FileSource("https://raw.githubusercontent.com/XAMPPRocky/tokei/v12.1.2/LICENCE-MIT", "ee1201a73de9b44ad1ef02a2f9f82705b1350b878e2bab3c3fb6282daf038a73"; filename="LICENCE-MIT"),
    FileSource("https://raw.githubusercontent.com/XAMPPRocky/tokei/v12.1.2/LICENCE-APACHE", "ebd8153ef4d2d160d0bdc76a1821ac2a0eb1f57e8c056f3674032f8140c41745"; filename="LICENCE-APACHE")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${bindir}

mv x86_64-apple-darwin14-tokei-dir/tokei x86_64-apple-darwin14-tokei
mv x86_64-linux-gnu-tokei-dir/tokei x86_64-linux-gnu-tokei
mv x86_64-linux-musl-tokei-dir/tokei x86_64-linux-musl-tokei

install_license LICENCE-MIT
install_license LICENCE-APACHE

mv "${target}-tokei" "${bindir}/tokei${exeext}"
chmod 755 "${bindir}/tokei${exeext}"
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("tokei", :tokei),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

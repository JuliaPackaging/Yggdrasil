using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "zig"
version = v"0.11.0"

# TODO: When BinaryBuilder supports LLVM 15, then build from source
url_prefix = "https://ziglang.org/download/$(version)/zig"
sources = [
    ArchiveSource("$(url_prefix)-linux-x86_64-$(version).tar.xz", "2d00e789fec4f71790a6e7bf83ff91d564943c5ee843c5fd966efc474b423047"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-x86-$(version).tar.xz", "7b0dc3e0e070ae0e0d2240b1892af6a1f9faac3516cae24e57f7a0e7b04662a8"; unpack_target = "i686-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-aarch64-$(version).tar.xz", "956eb095d8ba44ac6ebd27f7c9956e47d92937c103bf754745d0a39cdaa5d4c6"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos-x86_64-$(version).tar.xz", "1c1c6b9a906b42baae73656e24e108fd8444bb50b6e8fd03e9e7a3f8b5f05686"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos-aarch64-$(version).tar.xz", "c6ebf927bb13a707d74267474a9f553274e64906fd21bf1c75a20bde8cadf7b2"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64-$(version).zip", "142caa3b804d86b4752556c9b6b039b7517a08afa3af842645c7e2dcd125f652"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-windows-x86-$(version).zip", "e72b362897f28c671633e650aa05289f2e62b154efcca977094456c8dac3aefa"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("$(url_prefix)-freebsd-x86_64-$(version).tar.xz", "ea430327f9178377b79264a1d492868dcff056cd76d43a6fb00719203749e958"; unpack_target = "x86_64-unknown-freebsd13.4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/${target}/zig-*

mkdir -p ${bindir}/zig/
cp -r lib ${bindir}/zig/
cp zig${exeext} ${bindir}/zig/

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("x86_64", "freebsd")
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("zig/zig", :zig),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

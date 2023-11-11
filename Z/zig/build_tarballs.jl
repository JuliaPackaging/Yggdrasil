using BinaryBuilder, Pkg

# Collection of pre-build quarto binaries
name = "zig"
version = v"0.9.1"

# TODO: When BinaryBuilder supports LLVM 15, then build from source
url_prefix = "https://ziglang.org/download/$(version)/zig"
sources = [
    ArchiveSource("$(url_prefix)-linux-x86_64-$(version).tar.xz", "be8da632c1d3273f766b69244d80669fe4f5e27798654681d77c992f17c237d7"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-i386-$(version).tar.xz", "e776844fecd2e62fc40d94718891057a1dbca1816ff6013369e9a38c874374ca"; unpack_target = "i686-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-aarch64-$(version).tar.xz", "5d99a39cded1870a3fa95d4de4ce68ac2610cca440336cfd252ffdddc2b90e66"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-macos-x86_64-$(version).tar.xz", "2d94984972d67292b55c1eb1c00de46580e9916575d083003546e9a01166754c"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-macos-aarch64-$(version).tar.xz", "8c473082b4f0f819f1da05de2dbd0c1e891dff7d85d2c12b6ee876887d438287"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-windows-x86_64-$(version).zip", "443da53387d6ae8ba6bac4b3b90e9fef4ecbe545e1c5fa3a89485c36f5c0e3a2"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-windows-i386-$(version).zip", "74a640ed459914b96bcc572183a8db687bed0af08c30d2ea2f8eba03ae930f69"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("$(url_prefix)-freebsd-x86_64-$(version).tar.xz", "4e06009bd3ede34b72757eec1b5b291b30aa0d5046dadd16ecb6b34a02411254"; unpack_target = "x86_64-unknown-freebsd13.2"),
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

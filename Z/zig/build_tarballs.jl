using BinaryBuilder, Pkg

name = "zig"
version = v"0.15.2"

# Upstream pre-built binaries.  All sha256 sums verified against
# https://ziglang.org/download/index.json.
# TODO: When BinaryBuilder supports LLVM 20, then build from source (newer zig versions tend to use the most recent LLVM so this may continue to be a problem)
url_prefix = "https://ziglang.org/download/$(version)/zig"
sources = [
    ArchiveSource("$(url_prefix)-x86_64-linux-$(version).tar.xz", "02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86-linux-$(version).tar.xz", "4c6e23f39daa305e274197bfdff0d56ffd1750fc1de226ae10505c0eff52d7a5"; unpack_target = "i686-linux-gnu"),
    ArchiveSource("$(url_prefix)-aarch64-linux-$(version).tar.xz", "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86_64-macos-$(version).tar.xz", "375b6909fc1495d16fc2c7db9538f707456bfc3373b14ee83fdd3e22b3d43f7f"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-aarch64-macos-$(version).tar.xz", "3cc2bab367e185cdfb27501c4b30b1b0653c28d9f73df8dc91488e66ece5fa6b"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-x86_64-windows-$(version).zip", "3a0ed1e8799a2f8ce2a6e6290a9ff22e6906f8227865911fb7ddedc3cc14cb0c"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-x86-windows-$(version).zip", "7a6dfc00f4cc09ec46d3e10eb06f42538e92b6285e34debea7462edaf371da98"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("$(url_prefix)-aarch64-windows-$(version).zip", "b926465f8872bf983422257cd9ec248bb2b270996fbe8d57872cca13b56fc370"; unpack_target = "aarch64-w64-mingw32"),
    ArchiveSource("$(url_prefix)-x86_64-freebsd-$(version).tar.xz", "5509ff57cd3f219165caed0da10221739af82742b9edfcda3f7bfaf4da7212dd"; unpack_target = "x86_64-unknown-freebsd13.4"),
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

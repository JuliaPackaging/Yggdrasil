using BinaryBuilder, Pkg

name = "zig"
version = v"0.15.2"

# Upstream pre-built binaries.  All sha256 sums verified against
# https://ziglang.org/download/index.json.
# TODO: When BinaryBuilder supports LLVM 20, then build from source (newer zig versions tend to use the most recent LLVM so this may continue to be a problem)
url_prefix = "https://ziglang.org/download/$(version)/zig"
sources = [
    ArchiveSource("$(url_prefix)-x86_64-linux-$(version).tar.xz",      "02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239"),
    ArchiveSource("$(url_prefix)-x86-linux-$(version).tar.xz",         "4c6e23f39daa305e274197bfdff0d56ffd1750fc1de226ae10505c0eff52d7a5"),
    ArchiveSource("$(url_prefix)-aarch64-linux-$(version).tar.xz",     "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"),
    ArchiveSource("$(url_prefix)-powerpc64le-linux-$(version).tar.xz", "e182c5f8d30fc7f97d17d2ffef1488826aa3afaa51e5f0dbe14c597a98b45778"),
    ArchiveSource("$(url_prefix)-riscv64-linux-$(version).tar.xz",     "493512bdca485be3c6a9b0f69dcb4cbe4587f3af8e1be282fdd827108ba39930"),
    ArchiveSource("$(url_prefix)-x86_64-macos-$(version).tar.xz",      "375b6909fc1495d16fc2c7db9538f707456bfc3373b14ee83fdd3e22b3d43f7f"),
    ArchiveSource("$(url_prefix)-aarch64-macos-$(version).tar.xz",     "3cc2bab367e185cdfb27501c4b30b1b0653c28d9f73df8dc91488e66ece5fa6b"),
    ArchiveSource("$(url_prefix)-x86_64-windows-$(version).zip",       "3a0ed1e8799a2f8ce2a6e6290a9ff22e6906f8227865911fb7ddedc3cc14cb0c"),
    ArchiveSource("$(url_prefix)-x86-windows-$(version).zip",          "7a6dfc00f4cc09ec46d3e10eb06f42538e92b6285e34debea7462edaf371da98"),
    ArchiveSource("$(url_prefix)-x86_64-freebsd-$(version).tar.xz",    "5509ff57cd3f219165caed0da10221739af82742b9edfcda3f7bfaf4da7212dd"),
    ArchiveSource("$(url_prefix)-aarch64-freebsd-$(version).tar.xz",   "c62efd319f86663eb7747709dfca259205edba8eaee98efc96a51ce40a9437de"),
]

# Bash recipe
script = raw"""
case "${target}" in
    x86_64-linux-*)            zig_arch=x86_64-linux ;;
    i686-linux-*)              zig_arch=x86-linux ;;
    aarch64-linux-*)           zig_arch=aarch64-linux ;;
    powerpc64le-linux-*)       zig_arch=powerpc64le-linux ;;
    riscv64-linux-*)           zig_arch=riscv64-linux ;;
    x86_64-apple-darwin*)      zig_arch=x86_64-macos ;;
    aarch64-apple-darwin*)     zig_arch=aarch64-macos ;;
    x86_64-w64-mingw32)        zig_arch=x86_64-windows ;;
    i686-w64-mingw32)          zig_arch=x86-windows ;;
    x86_64-unknown-freebsd*)   zig_arch=x86_64-freebsd ;;
    aarch64-unknown-freebsd*)  zig_arch=aarch64-freebsd ;;
    *) echo "Unsupported target: ${target}" >&2; exit 1 ;;
esac

cd ${WORKSPACE}/srcdir/zig-${zig_arch}-*

mkdir -p ${bindir}/zig/
cp -r lib ${bindir}/zig/
cp zig${exeext} ${bindir}/zig/

install_license LICENSE
"""

# 32-bit ARM (armv6l/armv7l) is excluded: upstream's arm-linux binary lacks the
# EF_ARM_ABI_FLOAT_HARD ELF flag, which fails BinaryBuilder's *eabihf audit.
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("riscv64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("x86_64", "freebsd"),
    Platform("aarch64", "freebsd"),
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

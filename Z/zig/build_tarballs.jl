using BinaryBuilder, Pkg

name = "zig"
version = v"0.17.1"

# Upstream pre-built binaries.  All sha256 sums verified against
# https://ziglang.org/download/index.json.
# TODO: When BinaryBuilder supports LLVM 20, then build from source (newer zig versions tend to use the most recent LLVM so this may continue to be a problem)
url_prefix = "https://ziglang.org/download/$(version)/zig"
sources = [
    ArchiveSource("$(url_prefix)-x86_64-linux-$(version).tar.xz",      "3581863e3cbcfd0fce0efc682ce7e9e93da96668a977791d356a26d2a7e9b17a"),
    ArchiveSource("$(url_prefix)-x86-linux-$(version).tar.xz",         "0855367e096917bb0b628050d994d1871cc8c1f9192542163f9f93b6a30c9c6c"),
    ArchiveSource("$(url_prefix)-aarch64-linux-$(version).tar.xz",     "a1546d5646eb184437918d6635ca6b762a0e889eac09cef720ee7a1ed3fe7795"),
    ArchiveSource("$(url_prefix)-powerpc64le-linux-$(version).tar.xz", "f06911010b44fa4fdd8e8775669acf499310ff18e209bb392f2eb2428dccc05e"),
    ArchiveSource("$(url_prefix)-riscv64-linux-$(version).tar.xz",     "b31a3fd8b42b614cb68f93f18aab11c1721336654a9c8dd389ff7bab3a6827dc"),
    ArchiveSource("$(url_prefix)-x86_64-macos-$(version).tar.xz",      "9af07b20319fbd0c92ee46ad23e81d6a782b1aaea2cfb8dcbff35f1d2c7ddbb7"),
    ArchiveSource("$(url_prefix)-aarch64-macos-$(version).tar.xz",     "75f1bc7a1e9852f17ec9a0c1895f767c4ec56d46bc8a834920eece1d0359dd8d"),
    ArchiveSource("$(url_prefix)-x86_64-windows-$(version).zip",       "b03f477a1943673e02aca0f570e8030dffd536ce1f45cbc4d3326ec31159562e"),
    ArchiveSource("$(url_prefix)-x86-windows-$(version).zip",          "a93f48164339ecc3c2d8f470d5b5d8ec54895db3aabdd1737c216ddf9284fd8d"),
    ArchiveSource("$(url_prefix)-x86_64-freebsd-$(version).tar.xz",    "fd8b9728f05db2a9942fc1f18087c0e0d6dfccb7a51557b06cf026d3e4c78542"),
    ArchiveSource("$(url_prefix)-aarch64-freebsd-$(version).tar.xz",   "5ebd395db8996df2bfe1c252b5b6848ec8fad886192cbd88358fbcbf91c91703"),
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

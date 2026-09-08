using BinaryBuilder

# ============================================================================
# COORDINATION DRAFT — NOT FOR MERGE
#
# This branch (`ntl-12.0-coordination`) tracks NTL feature 002 work
# (`s-celles/ntl@002-remove-legacy-build`), which:
#   * REMOVES the legacy Perl ./configure + Makefile build path.
#   * Bumps NTL to 12.0.0 (SemVer major; BREAKING).
#   * Reintroduces auto-tuning via a Python tool (`ntl-wizard`) that is
#     native-only and refuses cross-compile contexts; cross builds
#     (this recipe) keep using static tune tables.
#
# Feature 002 depends on feature 001 (`ntl-meson-cross-compile` branch
# of the s-celles fork) landing first; do not open this as a JuliaPackaging
# PR until both upstream merges are in libntl/ntl and a v12.0.0 tag exists.
#
# Before merging upstream (sequence):
#   1. Land NTL feature 001 in libntl/ntl.
#   2. Land NTL feature 002 in libntl/ntl with the v12.0.0 tag.
#   3. Swap GitSource(s-celles/ntl, <SHA>) for
#      ArchiveSource("https://www.shoup.net/ntl/ntl-12.0.0.tar.gz", <hash>).
#   4. Remove this banner.
# ============================================================================

# NTL — A Library for doing Number Theory.
#
# NTL 12.0.0 (feature 002) uses Meson + Python as its sole build path.
# The Python Wizard (`ntl-wizard`) replaces the legacy Perl Wizard for
# native auto-tuning; cross-compile builds like this recipe consume the
# built-in static tune tables under src/meson/tune-tables/.
#
# The recipe never runs `ntl-wizard` — the Wizard explicitly refuses
# cross-build contexts (exit code 2) and is not needed: passing
# `-Dtune=default` lets Meson pick the appropriate static table from
# the host_machine.cpu_family (x86 family → x86, s390x → linux-s390x,
# else generic).

name = "ntl"
version = v"12.0.0"

# Source: s-celles/ntl @ 002-remove-legacy-build branch HEAD.
# Replace with ArchiveSource(...) of upstream tarball once v12.0.0 lands.
sources = [
    GitSource("https://github.com/s-celles/ntl.git",
              "a21fe6caf7ed45213ee08b68544ba669c48135bf"),
]

# Build script. The post-feature-002 recipe is simpler than the
# feature-001 draft: no per-target bash TUNE switching (Meson now does
# it internally via -Dtune=default), no Wizard invocation (cross-only
# build).
script = raw"""
cd $WORKSPACE/srcdir/ntl

# Normalize BinaryBuilder's ${target} into the form NTL's in-source ABI
# tables use (src/meson/abi-tables/<triplet>.ini):
#   - Strip Darwin version suffix:  x86_64-apple-darwin14 → x86_64-apple-darwin
#   - Strip FreeBSD version suffix: x86_64-unknown-freebsd14.1 → x86_64-unknown-freebsd
#   - BB uses `arm-linux-musleabihf` (with the gcc binary prefix
#     `arm-linux-musleabihf-`) for what NTL's spec calls
#     `armv7l-linux-gnueabihf-musl` — map it here.
case "$target" in
    *-apple-darwin*)         ABI_TRIPLET=$(echo "$target" | sed -E 's/(apple-darwin)[0-9.]+$/\1/') ;;
    *-unknown-freebsd*)      ABI_TRIPLET=$(echo "$target" | sed -E 's/(unknown-freebsd)[0-9.]+$/\1/') ;;
    arm-linux-musleabihf)    ABI_TRIPLET="armv7l-linux-gnueabihf-musl" ;;
    armv7l-linux-musleabihf) ABI_TRIPLET="armv7l-linux-gnueabihf-musl" ;;
    *)                       ABI_TRIPLET="$target" ;;
esac

# `-Dtune=default` is post-feature-002: Meson auto-picks per cpu_family
# (x86 family → x86, s390x → linux-s390x, else generic). The Python
# Wizard (`ntl-wizard`) is intentionally NOT invoked here — it is
# native-only and refuses cross contexts; cross packagers use the
# static tables shipped in the source tree.
meson setup \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --prefix="${prefix}" \
    --libdir="${libdir}" \
    --buildtype=release \
    -Dabi_triplet="${ABI_TRIPLET}" \
    -Dtune=default \
    -Dgmp=enabled \
    build

meson compile -C build
meson install -C build

install_license $WORKSPACE/srcdir/ntl/doc/copying.txt
"""

# Platforms — the FR-008 matrix, filtered through BB's supported list.
# Linux variants (glibc + musl), Apple Darwin (both arches), Windows
# (via MinGW-w64), FreeBSD, RISC-V (best-effort).
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686",   "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl", call_abi="eabihf"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("riscv64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686",   "windows"),
    Platform("x86_64", "freebsd"),
]
platforms = expand_cxxstring_abis(platforms)

# Products. Note: the Meson build emits `libntl-XX.dll` (versioned
# import name) on Windows and `libntl.so.0` on ELF / `libntl.0.dylib`
# on Mach-O. BB's LibraryProduct matches across all three.
products = [
    LibraryProduct("libntl", :libntl),
]

# Build deps + runtime deps.
dependencies = [
    Dependency("GMP_jll", v"6.2.1"; compat="6.2"),
]

# julia_compat marker: NTL is a C++ library; no Julia version constraint
# beyond what BinaryBuilder itself requires.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    clang_use_lld=false,
    julia_compat="1.6",
    preferred_gcc_version=v"10",
)

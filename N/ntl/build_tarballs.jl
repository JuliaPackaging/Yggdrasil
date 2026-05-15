using BinaryBuilder

# ============================================================================
# DRAFT — DO NOT MERGE TO JuliaPackaging/Yggdrasil/master.
#
# This recipe builds NTL from an unreleased fork (s-celles/ntl) at a
# specific commit on the work-in-progress Meson cross-compile branch.
# It is published here as a local dev loop for validating the cross-
# compile build across BinaryBuilder's full platform matrix before the
# upstream PR lands in libntl/ntl.
#
# Before merging upstream:
#   1. Land the Meson PR in libntl/ntl (tag e.g. v11.7.0).
#   2. Swap GitSource(s-celles/ntl, <SHA>) for
#      ArchiveSource("https://www.shoup.net/ntl/ntl-X.Y.Z.tar.gz", <hash>).
#   3. Bump the version field.
#   4. Remove this DRAFT banner.
# ============================================================================

# NTL — A Library for doing Number Theory.
#
# This recipe builds NTL using its new Meson build path (see
# https://github.com/s-celles/ntl/tree/001-meson-cross-compile and the
# design docs under specs/001-meson-cross-compile/), which is
# cross-compile-friendly. The legacy `./configure` + Makefile path
# remains the source of truth in upstream NTL; the Meson build cohabits
# with it. Once the Meson PR lands in libntl/ntl, switch the source to
# an ArchiveSource of the upstream tarball.
#
# The previous recipe shipped Linux x86/x86_64 (glibc + musl) only,
# because NTL's `./configure` runs target probes that cannot execute in
# the BinaryBuilder cross-compile sandbox. The Meson path puts every
# probe behind compile-time introspection or a per-target ABI table,
# unblocking the FR-008 platform matrix.

name = "ntl"
version = v"11.6.0"

# Source: the s-celles/ntl fork at the tip of the Meson cross-compile
# branch. Replace with ArchiveSource("https://www.shoup.net/ntl/...") +
# the upstream tarball hash once the Meson build lands upstream.
sources = [
    GitSource("https://github.com/s-celles/ntl.git",
              "0a5c14796356b33a181fd24222edf797cb9c7169"),
]

# Build script. Uses BinaryBuilder's $MESON_TARGET_TOOLCHAIN env var to
# pick the right cross-file for the current build target. The Meson
# build's in-source ABI table at src/meson/abi-tables/<triplet>.ini
# supplies every per-target property `cc.compiles()` cannot determine
# in cross mode.
script = raw"""
cd $WORKSPACE/srcdir/ntl

# The Meson build refuses to use NTL's auto-tuning Wizard (no target
# execution allowed under cross-compile). Per the spec, cross-compile
# users select a static tune table; `x86` is correct for x86 family
# targets, `generic` everywhere else.
case "${target}" in
    x86_64-*|i686-*)    TUNE=x86 ;;
    *)                  TUNE=generic ;;
esac

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

# Pass the normalized triplet so pick-abi.py looks up the right
# in-source ABI table.
meson setup \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --prefix="${prefix}" \
    --libdir="${libdir}" \
    --buildtype=release \
    -Dabi_triplet="${ABI_TRIPLET}" \
    -Dtune="${TUNE}" \
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
    julia_compat="1.6",
    preferred_gcc_version=v"10",
)

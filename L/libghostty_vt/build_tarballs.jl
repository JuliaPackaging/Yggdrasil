# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libghostty_vt"
version = v"1.0.0"

url_prefix = "https://release.files.ghostty.org/libghostty-vt/$(version)/libghostty-vt-$(version)"
sources = [
    # The release tarball plus the Zig packages it needs, so the build runs offline.
    # Checksums from the signed SHA256SUMS file next to the tarballs.
    ArchiveSource("$(url_prefix).tar.gz", "4a6ef758be721923e1969e7b81b443dcc92d8dd3fb5a39600c03a8817a753676"),
    ArchiveSource("$(url_prefix)-deps.tar.gz", "4d5ea5e448e4c7ea8fb55ccbaa8668f2a97d44f438cee831e2b7ecd162d85c29"),
]

# libghostty-vt requires Zig 0.17.x (`minimum_zig_version` in build.zig.zon).
zig_jll_version = v"0.17.1"

script = raw"""
export PATH="${host_bindir}/zig:${PATH}"
# Must start out empty, see PACKAGING-LIBGHOSTTY.md.
export ZIG_GLOBAL_CACHE_DIR=${WORKSPACE}/zig-global-cache
export ZIG_LOCAL_CACHE_DIR=${WORKSPACE}/zig-local-cache

# Zig links against its own bundled libc rather than the BinaryBuilder sysroot,
# so the glibc and macOS versions have to be part of the target.
cpu=baseline
simd=true
case "${bb_full_target}" in
    x86_64-linux-gnu*)         zig_target=x86_64-linux-gnu.2.17 ;;
    i686-linux-gnu*)           zig_target=x86-linux-gnu.2.17 ;;
    aarch64-linux-gnu*)        zig_target=aarch64-linux-gnu.2.17 ;;
    # The SIMD dependencies (simdutf, Highway) fail to build for some targets:
    # libc++ header errors on ppc64le and RVV intrinsics on riscv64.
    powerpc64le-linux-gnu*)    zig_target=powerpc64le-linux-gnu.2.17; simd=false ;;
    riscv64-linux-gnu*)        zig_target=riscv64-linux-gnu.2.35; simd=false ;;
    armv7l-linux-gnueabihf*)   zig_target=arm-linux-gnueabihf.2.19; cpu=generic+v7a+vfp3d16 ;;
    armv6l-linux-gnueabihf*)   zig_target=arm-linux-gnueabihf.2.19; cpu=arm1176jzf_s ;;
    x86_64-linux-musl*)        zig_target=x86_64-linux-musl ;;
    i686-linux-musl*)          zig_target=x86-linux-musl ;;
    aarch64-linux-musl*)       zig_target=aarch64-linux-musl ;;
    x86_64-apple-darwin*)      zig_target=x86_64-macos.10.14 ;;
    aarch64-apple-darwin*)     zig_target=aarch64-macos.11.0 ;;
    x86_64-w64-mingw32*)       zig_target=x86_64-windows-gnu ;;
    i686-w64-mingw32*)         zig_target=x86-windows-gnu ;;
    x86_64-unknown-freebsd*)   zig_target=x86_64-freebsd ;;
    aarch64-unknown-freebsd*)  zig_target=aarch64-freebsd ;;
    *) echo "Unsupported target: ${bb_full_target}" >&2; exit 1 ;;
esac

cd ${WORKSPACE}/srcdir/libghostty-vt-*-deps
deps_dir=$(pwd)
cd ${WORKSPACE}/srcdir/libghostty-vt-[0-9]*[0-9]

zig build \
    --prefix ${prefix} \
    --system ${deps_dir} \
    -Dtarget=${zig_target} \
    -Dcpu=${cpu} \
    -Dsimd=${simd} \
    -Doptimize=ReleaseFast \
    -Dstrip=true

rm -f ${libdir}/*.a ${prefix}/lib/*.a ${prefix}/lib/pkgconfig/libghostty-vt-static.pc
install_license LICENSE
"""

# Zig 0.17.1's standard library does not compile for 32-bit ARM musl
# (`std/os/linux.zig`: expected type 'u32', found 'u64').
platforms = filter(p -> !(arch(p) in ("armv6l", "armv7l") && libc(p) == "musl"), supported_platforms())

products = [
    LibraryProduct(["libghostty-vt", "ghostty-vt"], :libghostty_vt),
]

dependencies = [
    HostBuildDependency(PackageSpec(name="zig_jll", version=zig_jll_version)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "scx_capi"
version = v"0.1.0"

# C ABI over scx-core's chunked matrix stream (crates/scx-capi), used by ScxStream.jl.
sources = [
    GitSource("https://github.com/btraven00/scx.git", "09b7614bec9d9cb83874f7bab1828eea7491b781"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/scx
# Default features build a serial HDF5 from source and link it statically (hdf5-metno-src).
# HDF5_jll is not an option: every artifact since 1.14 is MPI-augmented.
# cmake-rs builds HDF5; it needs CMake >= 3.26 (rootfs has 3.21), so use the host CMake_jll one.
# Do not pass CMAKE_TARGET_TOOLCHAIN: it overrides the install prefix and HDF5 lands in ${prefix}
# instead of the crate's OUT_DIR, where hdf5-metno-sys looks for it.
export CMAKE=${host_bindir}/cmake
cargo build --release --locked -p scx-capi
install -Dvm 755 "target/${rust_target}/release/"*scx_capi.${dlext} -t "${libdir}"
install_license LICENSE
"""

platforms = supported_platforms()
# `cdylib` doesn't support musl
filter!(p -> libc(p) != "musl", platforms)
# cc-rs forces `-march` on 32-bit targets, which the BinaryBuilder compiler wrappers reject;
# nobody streams count matrices on 32-bit anyway.
filter!(p -> nbits(p) == 64, platforms)
# Windows: c-blosc (via zarrs) bundles a win32 pthread emulation that collides with the
# winpthreads the Rust gnu target links. (HDF5 would also need `-lshlwapi` for StrStrIA.)
filter!(!Sys.iswindows, platforms)
# No Rust toolchain shard for RISC-V or FreeBSD/aarch64
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

products = [
    LibraryProduct(["libscx_capi", "scx_capi"], :libscx_capi),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    # Rust links libgcc_s for unwinding on non-macOS targets.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

# scx-core's MSRV is 1.91 (zarrs).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", compilers=[:c, :rust], preferred_rust_version=v"1.91")

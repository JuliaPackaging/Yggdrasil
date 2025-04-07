# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "libimagequant"
version = v"4.3.4"

# Collection of sources required to complete build
#
sources = [
    GitSource(
        "https://github.com/ImageOptim/libimagequant.git",
        "b7340db2ac06bcdb36eec11f6251eee2c6d480b1"),
]

# following https://github.com/ImageOptim/libimagequant/tree/main/imagequant-sys#building-for-c
# we use cargo-c to install the library
script = raw"""
export CARGO_HOME="$WORKSPACE/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

cd $WORKSPACE/srcdir/libimagequant/imagequant-sys

# cargo-c 0.10.12 requires rust 1.84 which is not yet supported on Yggdrasil
# also, unset ENV variables since we want to compile cargo-c for the host, not the target
env -u CARGO_TARGET_DIR -u CARGO_BUILD_TARGET -u RUSTC_WRAPPER "/opt/${HOST_TARGET}/bin/cargo" install cargo-c --version 0.10.11 --target ${rust_host}
cargo cinstall --destdir=${sysroot} --prefix=${prefix} --libdir=${libdir}
install_license ./COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
# # Rust toolchain for i686 Windows is unusable
# filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# # Rust toolchain seems to not be available for RISC-V or FreeBSD/aarch64
# filter!(p -> arch(p) != "riscv64", platforms)
# filter!(p -> os(p) != "freebsd" || arch(p) != "aarch64", platforms)

# let's not waste CI until we get one platform working
platforms = [Platform("x86_64", "linux")]

# The products that we will ensure are always built
products = [
    LibraryProduct("libimagequant", :libimagequant),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)

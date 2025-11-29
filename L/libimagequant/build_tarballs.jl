# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "libimagequant"
version = v"4.4.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/ImageOptim/libimagequant.git",
        "24e2956a37cd7ad1f4b81c0e20318e3239eb71dc"),
        DirectorySource("./bundled"),
]

# following https://github.com/ImageOptim/libimagequant/tree/main/imagequant-sys#building-for-c
script = raw"""
export CARGO_HOME="$WORKSPACE/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

cd $WORKSPACE/srcdir/libimagequant/

# patch to create a dynamic library & disable no-opt build-script
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross-compile.patch

cd $WORKSPACE/srcdir/libimagequant/imagequant-sys

# Disable Rayon-threading (which apparently has large perf cost), because
# I can't get it to build on non-gnu
cargo build --release --no-default-features
install_license COPYRIGHT

# Install the shared library (note: _sys on the source path)
install -Dvm 755 ../target/${rust_target}/release/libimagequant_sys.${dlext} \
    ${libdir}/libimagequant.${dlext}


# Install the C header
install -Dvm 644 libimagequant.h ${includedir}/libimagequant.h
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
# # # Rust toolchain for i686 Windows is unusable
# filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# # # Rust toolchain seems to not be available for RISC-V or FreeBSD/aarch64
# filter!(p -> arch(p) != "riscv64", platforms)
# filter!(p -> os(p) != "freebsd" || arch(p) != "aarch64", platforms)

# let's not waste CI until we get two platforms working
platforms = [Platform("x86_64", "linux"), Platform("aarch64", "macos")]

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

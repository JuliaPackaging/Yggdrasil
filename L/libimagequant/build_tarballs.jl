# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "libimagequant"
version = v"4.3.4"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/ImageOptim/libimagequant.git",
        "26edfc4992a9b5c63c32945f676617c394ed1e31"),
        DirectorySource("./bundled"),
]

# following https://github.com/ImageOptim/libimagequant/tree/main/imagequant-sys#building-for-c
script = raw"""
export CARGO_HOME="$WORKSPACE/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

cd $WORKSPACE/srcdir/libimagequant/imagequant-sys

# patch to create a dynamic library as mentioned here:
# https://github.com/ImageOptim/libimagequant/tree/main?tab=readme-ov-file#c-dynamic-library-for-package-maintainers
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cdylib.patch

cargo build --release
install_license LICENSE

# Install the shared library
install -Dvm 755 target/${rust_target}/release/libimagequant.${dlext} \
    ${libdir}/libimagequant.${dlext}

# Install the C header
install -Dvm 644 ../libimagequant.h ${includedir}/libimagequant.h
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

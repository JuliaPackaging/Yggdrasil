# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Metatensor"
version = v"0.2.1"


# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://github.com/lab-cosmo/metatensor/releases/download/metatensor-core-v$version/metatensor-core-cxx-$version.tar.gz",
        "688751cb51900653edf2980bd80a52bbe187dff3c8b05cea9f1a1d3070b1e527"
    ),
]
# Bash recipe for building across all platforms
script = raw"""
apk del cmake

cd ${WORKSPACE}/srcdir/metatensor-core-*/

export EXTRA_RUST_FLAGS=""
if [[ "$target" == *musl* ]]; then
    export RUSTFLAGS="-Ctarget-feature=-crt-static $RUSTFLAGS"
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DRUST_BUILD_TARGET=${CARGO_BUILD_TARGET} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DMETATENSOR_INSTALL_BOTH_STATIC_SHARED=OFF \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms) # The code fails to link on 32-bit windows
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms) # Rust toolchain is not available on aarch64-unknown-freebsd
filter!(p -> arch(p) != "riscv64", platforms) # Rust toolchain is not available on riscv64

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmetatensor", "metatensor"], :libmetatensor)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.31.9+0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10",
    compilers=[:c, :rust],
)

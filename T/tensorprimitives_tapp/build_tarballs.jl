# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tensorprimitives_tapp"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lkdvos/tensorprimitives-rs.git", "ca916fae1947efa526cf7177bf06018c042fd8a6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tensorprimitives-rs
RFLAGS=()
if [[ "${target}" == *-musl* ]]; then
    RFLAGS+=(-C target-feature=-crt-static);
elif [[ "${target}" == *-apple-* ]]; then
    RFLAGS+=(-C link-arg=-Wl,-install_name,@rpath/libtensorprimitives_tapp.${dlext});
elif [[ "${target}" != *-mingw* ]]; then
    RFLAGS+=(-C link-arg=-Wl,-soname,libtensorprimitives_tapp.${dlext});
fi
export RUSTFLAGS="${RFLAGS[@]}"
export CARGO_PROFILE_RELEASE_DEBUG=0
export CARGO_TARGET_DIR=${WORKSPACE}/target
cargo build --release --locked -j${nproc} --target ${rust_target} -p tensorprimitives-tapp
crates/tensorprimitives-tapp/install.sh --prefix="${prefix}" --libdir="${libdir}" --includedir="${includedir}" --artifacts="${CARGO_TARGET_DIR}/${rust_target}/release" --no-licenses
install_license LICENSE-MIT LICENSE-APACHE
"""

# BinaryBuilder's Rust toolchain does not work for 32-bit Windows.
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) && arch(p) == "i686")

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtensorprimitives_tapp", "tensorprimitives_tapp"], :libtensorprimitives_tapp),
    FileProduct("include/tapp.h", :tapp_h)
]

# Dependencies that must be installed before this package can be built.
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])

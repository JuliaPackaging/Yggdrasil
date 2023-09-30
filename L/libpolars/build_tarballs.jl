# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libpolars"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/Pangoraw/Polars.jl/",
        "1860f4dd5a8750ffe2ab78268b72e7008cfe169d",
    ),
    ArchiveSource(
        "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.13.sdk.tar.xz",
        "a3a077385205039a7c6f9e2c98ecdf2a720b2a819da715e03e0630c75782c1e4",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# This requires macOS 10.13
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.13
    popd
fi

cd ${WORKSPACE}/srcdir/c-polars/

cargo build --release

install -Dvm 755 target/${rust_target}/release/deps/*polars.${dlext} "${libdir}/libpolars.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain is unusable on i686-w64-mingw32
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
# Also, can't build cdylib for Musl systems
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpolars", :libpolars),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :rust], julia_compat="1.6", lock_microarchitecture=false)

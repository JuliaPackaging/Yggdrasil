# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hyper"
version = v"0.14.18"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/hyperium/hyper/archive/refs/tags/v$(version).tar.gz",
                  "6095636d02ea5af3ff5f06d80b9466f7b58ba76339f39813b33c3f24c663fdef"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hyper*/
sed '21 a [lib]\ncrate-type=["cdylib"]\n' -i Cargo.toml
RUSTFLAGS="--cfg hyper_unstable_ffi" cargo build --release --features client,http1,http2,ffi
install -Dm 755 target/${rust_target}/release/*hyper.${dlext} "${libdir}/libhyper.${dlext}"
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
    LibraryProduct("libhyper", :libhyper),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")

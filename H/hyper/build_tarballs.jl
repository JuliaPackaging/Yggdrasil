# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hyper"
version = v"0.14.19"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/hyperium/hyper/archive/refs/tags/v$(version).tar.gz",
                  "fb455f0ce68d209556285f971d275a72cd1873619699d44369c46874920af436"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hyper*/
# Revert https://github.com/hyperium/hyper/commit/1c6637060e36654ddb2fdfccb0d146c7ad527476
# which prevents building shared libraries with the stable channel.
atomic_patch -p1 ../patches/revert-dont-build-c-lib.patch
RUSTFLAGS="--cfg hyper_unstable_ffi" cargo rustc --release --features client,http1,http2,ffi
install -Dvm 755 target/${rust_target}/release/*hyper.${dlext} "${libdir}/libhyper.${dlext}"
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

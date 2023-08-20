# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libpolars"
version = v"0.32.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Pangoraw/Polars.jl/",
              "9ad0fea96a4ba0d367a70bd48e643df54671b153"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-polars/

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

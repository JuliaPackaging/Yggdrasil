# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "tree_sitter_highlight"
version = v"0.20.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tree-sitter/tree-sitter/",
              "ccd6bf554d922596ce905730d98a77af368bba5c"),
]

# Bash recipe for building across all platforms
script = raw"""
ls
cd $WORKSPACE/srcdir/

# Use cargo-rustc to build tree-sitter-highlight as a dynamic library here vvvvvv
cargo rustc --release --manifest-path highlight/Cargo.toml -- --crate-type=cdylib

install -Dm 755 target/${rust_target}/release/deps/libtree_sitter_highlight-*.${dlext} "${libdir}/libtree_sitter_highlight.${dlext}"
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
    LibraryProduct("libtree_sitter_highlight", :libtree_sitter_highlight),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")

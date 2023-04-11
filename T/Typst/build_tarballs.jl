# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Typst"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/typst/typst.git", "b3faef4b80a674294091066e20501e3a5d0f6103")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/typst
cargo build -p typst-cli --release
install -Dvm 755 "target/${rust_target}/release/typst" "${bindir}/typst${exeext}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("typst", :typst),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers=[:rust, :c])

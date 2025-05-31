# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "resvg"
version = v"0.45.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/linebender/resvg.git", "1b6c2fddbcbeffa8135df4323b02aaae84890907")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/resvg*
cargo build --release
install -Dvm 755 "target/${rust_target}/release/resvg${exeext}" -t "${bindir}"
install_license LICENSE-MIT LICENSE-APACHE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> !(nbits(p) == 32 && Sys.iswindows(p)), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("resvg", :resvg)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])

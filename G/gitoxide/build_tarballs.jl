# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gitoxide"
# Note: upstream doesn't seem to tag new versions of `gitoxide` recently, but
# the version number comes from `Cargo.toml`.
version = v"0.11.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Byron/gitoxide",
              "7e76796d5c2956961bd998286bec05fca1ba8fc4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gitoxide*/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/ein${exeext}" "${bindir}/ein${exeext}"
install -Dvm 755 "target/${rust_target}/release/gix${exeext}" "${bindir}/gix${exeext}"
install_license LICENSE-*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# 32-bit systems don't seem to be supported at the moment
filter!(p -> nbits(p) == "64", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ein", :ein),
    ExecutableProduct("gix", :gix),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5",
               compilers=[:c, :rust], lock_microarchitecture=false)

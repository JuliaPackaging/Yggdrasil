# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "stork"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jameslittle230/stork.git",
              "b946a7837bf13443e6ca0f4887d093a5b398d875"),
]

# Adapted from the justfile of the repo
script = raw"""
cd $WORKSPACE/srcdir/stork
cargo build --release --all-features
install -Dvm 0755 "target/${rust_target}/release/stork${exeext}" "${bindir}/stork${exeext}"
install_license license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(supported_platforms()) do p
    Sys.islinux(p) && arch(p) in ("x86_64","aarch64","powerpc64le")
end
# The products that we will ensure are always built
products = [
    ExecutableProduct("stork", :stork),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])

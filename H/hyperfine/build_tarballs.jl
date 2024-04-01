# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hyperfine"
version = v"1.15.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/sharkdp/hyperfine/archive/refs/tags/v$(version).tar.gz",
                  "b1a7a11a1352cdb549cc098dd9caa6c231947cc4dd9cd91ec25072d6d2978172"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hyperfine*/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/hyperfine${exeext}" "${bindir}/hyperfine${exeext}"
install_license LICENSE-*
"""

platforms = supported_platforms(; exclude=p->Sys.iswindows(p) && arch(p)=="i686")

# The products that we will ensure are always built
products = [
    ExecutableProduct("hyperfine", :hyperfine),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # hyperfine links to libgcc_s on non-macOS for unwinding
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust],
               )

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Zellij"
version = v"0.24.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/zellij-org/zellij/archive/refs/tags/v$(version).tar.gz",
                  "a7f2d1fa1dd9c55d37d1daebdf6af3c6666d144ee1e85ac7f805544ae03e3b1e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zellij*/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/zellij${exeext}" "${bindir}/zellij${exeext}"
"""

platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("zellij", :zellij),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust],
               # Wasmer wants to use `-march`, sigh.
               lock_microarchitecture=false,
               )

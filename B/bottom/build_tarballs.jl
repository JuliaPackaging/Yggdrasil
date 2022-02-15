# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "bottom"
version = v"0.6.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ClementTsang/bottom/archive/refs/tags/$(version).tar.gz",
                  "4e4eb251972a7af8c46dd36bcf1335fea334fb670569434fbfd594208905b2d9"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bottom*/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/btm${exeext}" "${bindir}/btm${exeext}"
"""

# This doesn't work on FreeBSD: https://github.com/ClementTsang/bottom/issues/480.  And our
# Rust toolchain for i686 is unusable.
platforms = supported_platforms(; exclude=p -> Sys.isfreebsd(p) || (Sys.iswindows(p) && arch(p) == "i686"))

# The products that we will ensure are always built
products = [
    ExecutableProduct("btm", :btm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])

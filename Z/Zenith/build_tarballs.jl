# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Zenith"
version = v"0.13.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/bvaisvil/zenith/archive/refs/tags/$(version).tar.gz",
                  "1f2914a1ddd7dd76cca0e0c07ca77bd048addfd80fc6329ea7b83647ea66020a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zenith*/
# Get rid of misleading settings
rm -rf .cargo
cargo build --release
install -Dvm 755 "target/${rust_target}/release/zenith${exeext}" "${bindir}/zenith${exeext}"
"""

# This works only on Unix systems, but not FreeBSD:
# https://github.com/bvaisvil/zenith/issues/8
platforms = supported_platforms(; exclude=p -> Sys.iswindows(p) || Sys.isfreebsd(p))

# The products that we will ensure are always built
products = [
    ExecutableProduct("zenith", :zenith),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])

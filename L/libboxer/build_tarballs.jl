# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libboxer"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/feenkcom/libboxer/archive/refs/tags/v$(version).tar.gz",
                  "57d25e5339b0c7b1d8c8242484ce2c4baca05fbea035c8e2d8aab05573eed0c9"),
]

# Adapted from the justfile of the repo
script = raw"""
cd $WORKSPACE/srcdir/libboxer*
cargo build --release
install -Dvm 0755 "target/${rust_target}/release/libBoxer.${dlext}" "${libdir}/libBoxer.${dlext}"
install_license LICENSE
cbindgen --config cbindgen.toml --crate libboxer --output boxer.h
install -Dvm 0755 "boxer.h" "${includedir}/boxer.h"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(supported_platforms()) do p
    libc(p) != "musl"
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libBoxer", :libBoxer),
    FileProduct("include/boxer.h", :boxer_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("cbindgen_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])

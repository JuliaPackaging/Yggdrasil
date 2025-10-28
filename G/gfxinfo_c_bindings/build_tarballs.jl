# Note that this script can accept some limited command-line arguments, type
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gfxinfo_c_bindings"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/simeonschaub/gfxinfo_c_bindings.git",
              "a5c3d4a6aeab6937ec57976660ee8114f5f9af88"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gfxinfo_c_bindings/
cargo build --release
install -Dm755 target/${rust_target}/release/libgfxinfo_c_bindings.${dlext} ${libdir}/libgfxinfo_c_bindings.${dlext}
install_license /usr/share/licenses/MIT /usr/share/licenses/APL2
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgfxinfo_c_bindings", :libgfxinfo_c_bindings),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libdrm_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])

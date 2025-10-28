# Note that this script can accept some limited command-line arguments, type
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gfxinfo_c_bindings"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/simeonschaub/gfxinfo_c_bindings.git",
              "5c2be51a8d87625ab171926abe573bf4ff808030"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gfxinfo_c_bindings/
cargo build --release
install -Dvm 755 target/${rust_target}/release/*gfxinfo_c_bindings.${dlext} -t "${libdir}"
install_license LICENSE /usr/share/licenses/APL2
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# nvml_wrapper crate doesn't support freebsd
filter!(p -> !Sys.isfreebsd(p), platforms)

# We don't have rust for these platforms
filter!(p -> arch(p) != "riscv64", platforms)

# Cannot produce cdylib on musl
filter!(p -> libc(p) != "musl", platforms)

# Rust cross compile is broken for this platform (https://github.com/rust-lang/rust/issues/79609)
filter!(p-> p != Platform("i686", "windows"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgfxinfo_c_bindings", "gfxinfo_c_bindings"], :libgfxinfo_c_bindings),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libdrm_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])

# Note that this script can accept sredome limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Zenohd"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eclipse-zenoh/zenoh.git",
              "b70ee93327d5d81e14cfd967587b3bdd55c53c41")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zenoh
install_license LICENSE
# set up the host compiler for use by the ring native compilation path
export CC_$(echo $rust_host | sed "s/-/_/g")=$CC_BUILD
# needed to build dylibs on musl
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi
# update static_init_macro to support cross-compilation
cargo update -p static_init_macro
cargo build --release --all-targets
install -Dvm 0755 "target/${rust_target}/release/zenohd${exeext}" "${bindir}/zenohd${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# x86-64 Apple targets seem to be missing an API
filter!(p -> !Sys.isapple(p) || arch(p) != "x86_64", platforms)
# Rust toolchain is not available for RISC-V
filter!(p -> arch(p) != "riscv64", platforms)
# zenoh doesn't support FreeBSD (missing `set_bind_to_device_tcp_socket` in `zenoh_util::net`)
filter!(p -> os(p) != "freebsd", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("zenohd", :zenohd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", compilers = [:rust, :c],
               preferred_gcc_version = v"14.2.0", lock_microarchitecture = false)

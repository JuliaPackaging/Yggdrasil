# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Zenoh"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eclipse-zenoh/zenoh-c.git", "c75c8034513f8e94a516f2b09dcdb47aeedda9c0")
]

# Bash recipe for building across all platforms
# sets up the host compiler for use by the ring native compilation path
script = raw"""
cd $WORKSPACE/srcdir/zenoh-c
install_license LICENSE

export CC_$(echo $rust_host | sed "s/-/_/g")=$CC_BUILD

# needed to build dylibs on musl
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

mkdir -p build && cd build
cmake -S .. -B . \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DZENOHC_CUSTOM_TARGET=${rust_target}
cmake --build . --target install --config Release --parallel ${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Rust toolchain is not available for RISC-V
filter!(p -> arch(p) != "riscv64", platforms)
# zenoh doesn't support FreeBSD (missing `set_bind_to_device_tcp_socket` in `zenoh_util::net`)
filter!(p -> os(p) != "freebsd", platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libzenohc", "zenohc"], :libzenohc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", compilers = [:rust, :c],
               preferred_gcc_version = v"14.2.0", lock_microarchitecture = false)

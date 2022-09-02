# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "sccache"
version = v"0.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mozilla/sccache/archive/refs/tags/v$(version).tar.gz",
                  "26585447d07f67d0336125816680a2a5f7381065a03de3fd423a3b5c41eb637c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sccache-*
cargo build --release
install -Dvm 755 "target/${rust_target}/release/sccache${exeext}" "${bindir}/sccache${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Build for PowerPC fails with
#     error: failed to run custom build command for `ring v0.16.20`
#
#     Caused by:
#       process didn't exit successfully: `/workspace/srcdir/sccache-0.3.0/target/release/build/ring-8d2555dae0cf11a2/build-script-build` (exit status: 101)
#       --- stderr
#       thread 'main' panicked at 'called `Option::unwrap()` on a `None` value', /opt/x86_64-linux-musl/registry/src/github.com-1ecc6299db9ec823/ring-0.16.20/build.rs:358:10
filter!(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("sccache", :sccache),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.17"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)

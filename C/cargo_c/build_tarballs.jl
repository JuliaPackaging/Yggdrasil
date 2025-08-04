# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cargo_c"
version = v"0.10.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lu-zero/cargo-c", "d1da3c27a0defdceba12c2b2762094cdde6c0337"),
    FileSource("https://github.com/lu-zero/cargo-c/releases/download/v$(version)/Cargo.lock", "0af99496210d7e5cb70de6643b571a8882120148e628d7a75327937b64fd9841")
]

# Bash recipe for building across all platforms
script = raw"""
cp $WORKSPACE/srcdir/Cargo.lock $WORKSPACE/srcdir/cargo-c/
cd $WORKSPACE/srcdir/cargo-c/
cargo build --release --locked --features=vendored-openssl
install -Dvm 755 "target/${rust_target}/release/cargo-capi${exeext}" "${bindir}/cargo-capi${exeext}"
install -Dvm 755 "target/${rust_target}/release/cargo-cinstall${exeext}" "${bindir}/cargo-cinstall${exeext}"
install -Dvm 755 "target/${rust_target}/release/cargo-cbuild${exeext}" "${bindir}/cargo-cbuild${exeext}"
install -Dvm 755 "target/${rust_target}/release/cargo-ctest${exeext}" "${bindir}/cargo-ctest${exeext}"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Rust toolchain 1.87.0 not available on platform aarch64-unknown-freebsd or riscv64-linux-gnu
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
# Errors with "ld: library not found for -lclang_rt.osx"
filter!(p -> !Sys.isapple(p), platforms)
# # Has issue 
# filter!(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("cargo-capi", :cargo_capi),
    ExecutableProduct("cargo-cinstall", :cargo_cinstall),
    ExecutableProduct("cargo-cbuild", :cargo_cbuild),
    ExecutableProduct("cargo-ctest", :cargo_ctest),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # Dependency("OpenSSL_jll"; compat="3.0.15"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                compilers=[:c, :rust], julia_compat="1.6",
                lock_microarchitecture=false)

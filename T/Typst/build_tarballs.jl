# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Typst"
version = v"0.14.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/typst/typst.git", "b33de9de113c91c184214b299bd7a8eb3070c3ab")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/typst
cargo build -p typst-cli --release
install -Dvm 755 "target/${rust_target}/release/typst${exeext}" "${bindir}/typst${exeext}"
install_license LICENSE
"""

# Things don't work on musl. The OpenSSL libraries `ssl` and `crypto`
# are not found. The reason is that rust wants to link statically and
# is looking for static libraries which we do not provide.
#
# We can tell rust to use dynamic linking via
# `export RUSTFLAGS="-C target-feature=-crt-static"`
# but then we run into the undefined symbol
# `posix_spawn_file_actions_addchdir_np` because our musl library is
# too old.
#
# Therefore we disable musl. Maybe we can switch to a newer musl at some point.

platforms = supported_platforms(; exclude = p ->
    arch(p) == "riscv64" ||     # rust not available
    (Sys.isfreebsd(p) && arch(p) == "aarch64") || # rust not available
    (Sys.iswindows(p) && arch(p) == "i686") || # rust linker fails
    libc(p) == "musl" # see above
)

# The products that we will ensure are always built
products = [
    ExecutableProduct("typst", :typst),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:rust, :c], lock_microarchitecture=false,
               preferred_gcc_version = v"5")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "vole"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/peal/vole/releases/download/v$(version)/vole-$(version).tar.gz",
                  "5f125fc23c5344f4b0f831d272e8c630b776f11f52997f8db767792c9f594bde"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/vole*
cd rust
cargo build --release --bin vole
mkdir -p "${bindir}"
install -Dvm 755 "target/${rust_target}/release/vole${exeext}" "${bindir}/."
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# Rust toolchain seems to not be available for RISC-V or FreeBSD/aarch64
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> os(p) != "freebsd" || arch(p) != "aarch64", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("vole", :vole),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "CoverM"
version = v"0.7.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/wwood/CoverM",
        "5edadabe744b3b92911179614468c43630450699"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoverM/
cargo build --release
install -Dvm 0755 "target/${rust_target}/release/coverm${exeext}" "${bindir}/coverm${exeext}"
install_license LICENCE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(supported_platforms()) do platform
    # Windows can't compile the dep htslib-rust for now, and I don't care about
    # other platforms
    (Sys.isapple(platform) || Sys.islinux(platform)) &&
    in(arch(platform), ("x86_64", "aarch64")) &&

    # aarch64 linux errors, https://github.com/rust-bio/rust-htslib/issues/425
    !(arch(platform) == "aarch64" && Sys.islinux(platform))
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("coverm", :coverm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)

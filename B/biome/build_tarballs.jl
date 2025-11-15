# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "biome"
#version = v"2.3.5"
version = v"2.0.6"

# Collection of sources required to complete build
sources = [
    # ArchiveSource("https://github.com/biomejs/biome/archive/refs/tags/@biomejs/biome@2.3.5.tar.gz",
    #               "39c685ea028d5dd8db101b93c96a0956fb6f7846da93caa49231a62c612daa77"),
    ArchiveSource("https://github.com/biomejs/biome/archive/refs/tags/@biomejs/biome@2.0.6.tar.gz",
                  "52d5e449346bfb15855a3bac85ba5d43b81d0fb1a99be9d4b7dca8c51521404c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/biome--biomejs-biome-*/
# The BIOME_VERSION stuff is some weird stuff you need to do. From
# Biome's CONTRIBUTING.md about production builds:
#
# > Usually, the easiest way to create a production build is to use the --release flag, however
# > Biome requires an environment variable called BIOME_VERSION to generate different code at
# > compile time.
# >
# > When you provide a BIOME_VERSION that is different from 0.0.0, the build will turn off all
# > the nursery rules that are recommended. The value of BIOME_VERSION doesn't matter, as long
# > as it's different from 0.0.0.
#
# <https://github.com/biomejs/biome/blob/main/CONTRIBUTING.md#production-binaries>
BIOME_VERSION=0.0.1 cargo build --bin biome --release
mkdir -p "${bindir}"
cp "target/${rust_target}/release/biome${exeext}" "${bindir}/."
install_license LICENSE-APACHE LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)
# We don't have rust for these platforms
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("biome", :biome),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               #compilers=[:c, :rust], julia_compat="1.6", preferred_rust_version=v"1.91",
               compilers=[:c, :rust], julia_compat="1.6", preferred_rust_version=v"1.87",
               lock_microarchitecture=false)

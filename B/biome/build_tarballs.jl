# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "biome"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/biomejs/biome.git",
        "f4bf3411cc34ae6458b298a03c6255ac3cd00231"), # @biomejs/biome@2.4.8
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
install -Dvm 755 "target/${rust_target}/release/biome${exeext}" "${bindir}/biome${exeext}"
install_license LICENSE-APACHE LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !(arch(p) == "i686" && Sys.iswindows(p)), platforms)
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
    compilers=[:c, :rust], julia_compat="1.6", preferred_rust_version=v"1.94",
    lock_microarchitecture=false)

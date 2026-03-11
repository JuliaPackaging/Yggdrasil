# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "satsuma"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/markusa4/satsuma", "be6beeb6d2538aa133b1f6b7cad84655cda950bb"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/satsuma

for f in $WORKSPACE/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cp $WORKSPACE/srcdir/tsl/* tsl/

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release

make -C build satsuma
install -Dvm 755 build/satsuma -t "${bindir}"
install_license LICENSE
"""

sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows) |> expand_cxxstring_abis
# The products that we will ensure are always built
products = [
    ExecutableProduct("satsuma", :satsuma)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"13")

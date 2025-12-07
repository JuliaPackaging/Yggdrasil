# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "ParseGen"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sandialabs/parsegen-cpp.git",
              "3da1e0d1aef608eb2a6abeb84638bfd8327612e1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/parsegen-cpp*/

install_license LICENSE
mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON

make -j${nproc}
make install
"""

# install a newer SDK which supports `std::filesystem`
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libparsegen", :libparsegen)
    ExecutableProduct("parsegen-calc", :parsegen_calc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
#this uses std filesystem, so we need gcc 8 at least
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")

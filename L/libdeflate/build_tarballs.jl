# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libdeflate"
version = v"1.25"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/ebiggers/libdeflate",
        "c8c56a20f8f621e6a966b716b31f1dedab6a41e3"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libdeflate
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/libdeflate/COPYING
"""

# This requires macOS 10.13
sources, script = require_macos_sdk("10.13", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdeflate", :libdeflate)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")

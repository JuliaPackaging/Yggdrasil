# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "spirv2clc"
version = v"0.1"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/kpet/spirv2clc",
              "da46ad1dfc7754fb3aa7032da51c023b49e648af")
]

# Bash recipe for building across all platforms
script = raw"""
cd spirv2clc
install_license LICENSE

# check-out vendored submodules
# TODO: use JLLs?
git submodule update --init

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# XXX: the library does not have a C API, so we don't bother building it
#CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc}

# install rules seem messed up because the SPIRV-Tools inclusion,
# so only install the tool we need
install -v -Dm755 build/tools/spirv2clc${exeext} -t ${prefix}/bin
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv2clc", :spirv2clc),
]

# Dependencies that must be installed before this package can be built
dependencies = []

build_tarballs(ARGS,
               name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10",
               julia_compat="1.6")

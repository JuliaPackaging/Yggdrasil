# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_Tools"
version = v"2023.2"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "44d72a9b36702f093dd20815561a56778b2d181e"),
    # vendored dependencies, see the DEPS file
    GitSource("https://github.com/google/effcee.git", "66edefd2bb641de8a2f46b476de21f227fc03a28"),
    GitSource("https://github.com/google/googletest", "a3580180d16923d6d5f488e20b3814608a892f17"),
    GitSource("https://github.com/google/re2.git", "c9cba76063cf4235c1a15dd14a24a4ef8d623761"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "268a061764ee69f09a477a695bf6a11ffe311b8d"),
]

# Bash recipe for building across all platforms
script = raw"""
# put vendored dependencies in places they will be picked up by the build system
mv effcee SPIRV-Tools/external/effcee
mv re2 SPIRV-Tools/external/re2
mv googletest SPIRV-Tools/external/googletest
mv SPIRV-Headers SPIRV-Tools/external/spirv-headers

cd SPIRV-Tools
install_license LICENSE

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Skip tests
CMAKE_FLAGS+=(-DSPIRV_SKIP_TESTS=ON)

# Don't use -Werror
CMAKE_FLAGS+=(-DSPIRV_WERROR=OFF)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv-as", :spirv_as),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    ExecutableProduct("spirv-val", :spirv_val),
    LibraryProduct("libSPIRV-Tools-shared", :libSPIRV_Tools),
]

# Dependencies that must be installed before this package can be built
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7") # requires C++17

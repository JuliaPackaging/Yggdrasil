using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

# ASDF - Advanced Scientific Data Format, a C++ implementation

name = "asdf_cxx"
version = v"8.0.1"

# Collection of sources required to build asdf-cxx
sources = [
    GitSource("https://github.com/eschnett/asdf-cxx", "abaa4a92d41c10e5c16ccbfbd7857a0a8bc19533"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/asdf-cxx
cmake -S . -B build \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel $nproc
cmake --install build
install_license LICENSE.rst
"""

# The x86_64 _Float16 conversion helpers `__extendhfsf2` and `__truncsfhf2`
# are only in libSystem since macOS 10.11
sources, script = require_macos_sdk("10.12", sources, script)

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Blosc2_jll"; compat="301.300.300"),
    Dependency("Blosc_jll"; compat="1.21.7"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Lz4_jll"; compat="1.10.1"),
    Dependency("OpenSSL_jll"; compat="3.5.0"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("yaml_cpp_jll"; compat="0.9.0"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("asdf-copy", :asdf_copy),
    ExecutableProduct("asdf-demo", :asdf_demo),
    ExecutableProduct("asdf-demo-compression", :asdf_demo_compression),
    ExecutableProduct("asdf-demo-external", :asdf_demo_external),
    ExecutableProduct("asdf-demo-large", :asdf_demo_large),
    ExecutableProduct("asdf-ls", :asdf_ls),
    LibraryProduct("libasdf-cxx", :libasdf_cxx),
]

# C++17 requires a new-ish GCC
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")

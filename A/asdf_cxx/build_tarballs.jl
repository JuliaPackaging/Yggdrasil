using BinaryBuilder

# ASDF - Advanced Scientific Data Format, a C++ implementation

name = "asdf_cxx"
version = v"7.3.2"

# Collection of sources required to build asdf-cxx
sources = [
    GitSource("https://github.com/eschnett/asdf-cxx", "abfdeb28d3d5b11f94f3937c082e3c5747710678"),
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

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Blosc2_jll"; compat="201.1500.0"),
    Dependency("Blosc_jll"; compat="1.21.1"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("OpenSSL_jll"; compat="3.0.10"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("yaml_cpp_jll"),
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

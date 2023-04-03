# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SZ3"
version = v"3.1.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/szcompressor/SZ3/releases/download/v$(version)/SZ3-$(version).zip",
                  "cf3ba7fae82f9483c4089963b9951ba9bf6b9eca5f712727fb92f2390b778aa8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
cd SZ3-*

mkdir build
cd build
cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_H5Z_FILTER=ON \
    -DBUILD_MDZ=ON \
    ..
cmake --build . --config RelWithDebInfo --parallel $nproc
# Fix permissions on generated file (chmod does not work)
cat SZ3ConfigVersion.cmake >SZ3ConfigVersion.cmake.tmp
mv SZ3ConfigVersion.cmake.tmp SZ3ConfigVersion.cmake
cmake --build . --config RelWithDebInfo --parallel $nproc --target install
install_license ../copyright-and-BSD-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mdz", :mdz),
    ExecutableProduct("mdz_smoke_test", :mdz_smoke_test),
    ExecutableProduct("sz3", :sz3),
    ExecutableProduct("sz3_smoke_test", :sz3_smoke_test),
    LibraryProduct("libhdf5sz3", :libhdf5sz3),
    LibraryProduct("libSZ3c", :libSZ3c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="GSL_jll")),
    Dependency(PackageSpec(name="HDF5_jll")),
    Dependency(PackageSpec(name="Zstd_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 8 since we require newer features of C++17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")

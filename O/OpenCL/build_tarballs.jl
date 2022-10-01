# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OpenCL"
version = v"2022.09.23"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/KhronosGroup/OpenCL-ICD-Loader.git", "3dae4803532b11d74e4dc216ee72570c1a4bff24")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license ./OpenCL-ICD-Loader/LICENSE

cmake -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -S ./OpenCL-ICD-Loader -B ./OpenCL-ICD-Loader/build
cmake --build ./OpenCL-ICD-Loader/build --target install -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libOpenCL", :libcl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="OpenCL_Headers_jll", version=v"2022.09.23")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")

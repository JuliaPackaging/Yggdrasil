# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenCL"
version = v"2022.9.23"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/KhronosGroup/OpenCL-Headers.git", "4c50fabe3774bad4bdda9c1ca92c82574109a74a"),
    GitSource("https://github.com/KhronosGroup/OpenCL-ICD-Loader.git", "3dae4803532b11d74e4dc216ee72570c1a4bff24")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

install_license ./OpenCL-Headers/LICENSE

wget https://patch-diff.githubusercontent.com/raw/KhronosGroup/OpenCL-Headers/pull/209.patch
patch ./OpenCL-Headers/tests/test_headers.c 209.patch

cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -S ./OpenCL-Headers -B ./OpenCL-Headers/build
cmake --build ./OpenCL-Headers/build --target install -j${nproc}

cmake -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -S ./OpenCL-ICD-Loader -B ./OpenCL-ICD-Loader/build
cmake --build ./OpenCL-ICD-Loader/build --target install -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    FileProduct("include/CL/cl.h", :cl_h),
    LibraryProduct("libOpenCL", :libcl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")

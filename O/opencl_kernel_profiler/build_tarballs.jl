# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "opencl_kernel_profiler"
version = v"0.0.109"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rjodinchr/opencl-kernel-profiler",
              "40e48f894bdce54866d2fb16d8cdb76c935f08df"),
    GitSource("https://github.com/google/perfetto",
              "2c4d2ffa7ff300e0b0feb8b8553e42afc7945870"),
]


# Bash recipe for building across all platforms
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir/opencl-kernel-profiler
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOPENCL_HEADER_PATH=${includedir}/CL \
    -DPERFETTO_SDK_PATH=../perfetto/sdk
cmake --build build --parallel ${nproc}
install -vm 644 build/libopencl-kernel-profiler.${dlext} "${libdir}/"
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter(p -> libc(p) == "glibc", supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libopencl-kernel-profiler", :libopencl_kernel_profiler),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="OpenCL_Headers_jll", version=v"2024.10.24")),
    Dependency("OpenCL_jll"),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.24.3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")

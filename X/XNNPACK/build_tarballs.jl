# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XNNPACK"
version = v"0.0.20210622" # i.e. https://github.com/google/XNNPACK/tree/79cd5f9e18ad0925ac9a050b00ea5a36230072db

cpuinfo_build_version = v"0.0.20201217" # https://github.com/google/XNNPACK/blob/79cd5f9e18ad0925ac9a050b00ea5a36230072db/cmake/DownloadCpuinfo.cmake#L15

cpuinfo_compat = [
    cpuinfo_build_version, # Torch-compatible version, due to pytorch v1.8.0 - v1.12.1, e.g. https://github.com/pytorch/pytorch/tree/v1.8.0/third_party / cpuinfo @ 5916273f79a21551890fd3d56fc5375a78d1598d
]

pthreadpool_build_version = v"0.0.20201206" # https://github.com/google/XNNPACK/blob/79cd5f9e18ad0925ac9a050b00ea5a36230072db/cmake/DownloadPThreadPool.cmake#L15

pthreadpool_compat = [
    pthreadpool_build_version,
    v"0.0.20210414", # Torch-compatible version, due to pytorch v1.9.0 - v1.12.1, e.g. https://github.com/pytorch/pytorch/tree/v1.9.0/third_party / pthreadpool @ a134dd5d4cee80cce15db81a72e7f929d71dd413
]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/XNNPACK.git", "79cd5f9e18ad0925ac9a050b00ea5a36230072db"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/XNNPACK
atomic_patch -p1 ../patches/xnnpack-soversion.patch
atomic_patch -p1 ../patches/xnnpack-freebsd.patch
atomic_patch -p1 ../patches/xnnpack-w64-system-libs.patch
C_FLAGS=()
# if [[ $bb_full_target == armv7l-*march+neonvfpv4 ]]; then # Requires build for specific micro-architecture
#     atomic_patch -p1 ../patches/xnnpack-arm-exclude-microkernel-srcs.patch
#     C_FLAGS+="-DXNN_NO_F32_OPERATORS "
#     C_FLAGS+="-DXNN_NO_QS8_OPERATORS "
if [[ $bb_full_target == aarch64-* ]]; then # Building for aarch64-*march+armv8*
    atomic_patch -p1 ../patches/xnnpack-aarch64-exclude-microkernel-srcs.patch
    atomic_patch -p1 ../patches/xnnpack-aarch64-armv8-exclude-microkernel-srcs.patch
    C_FLAGS+="-DXNN_NO_F16_OPERATORS "
    C_FLAGS+="-DXNN_NO_F32_OPERATORS "
    C_FLAGS+="-DXNN_NO_QS8_OPERATORS "
# elif [[ $bb_full_target == aarch64-apple-*march+apple_m1* ]]; then # Requires build for specific micro-architecture
#     atomic_patch -p1 ../patches/xnnpack-aarch64-exclude-microkernel-srcs.patch
#     C_FLAGS+="-DXNN_NO_F16_OPERATORS "
fi
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=$libdir \
    -DXNNPACK_LIBRARY_TYPE=shared \
    -DXNNPACK_BUILD_TESTS=OFF \
    -DXNNPACK_BUILD_BENCHMARKS=OFF \
    -DXNNPACK_USE_SYSTEM_LIBS=ON \
    -DCMAKE_C_FLAGS="$C_FLAGS" \
    ..
cmake --build . -- -j $nproc
make install/local
if [[ $target == *-w64-mingw32 ]]; then
    install -Dvm 755 libXNNPACK.dll "${libdir}/libXNNPACK.dll"
fi
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) != "armv6l", platforms) # armv6l is unsupported by XNNPACK (lacks NEON instructions)
filter!(p -> arch(p) != "armv7l", platforms) # Requires build for specific micro-architecture (neonvfpv4)
filter!(p -> arch(p) != "powerpc64le", platforms) # PowerPC64LE is unsupported by XNNPACK (Unsupported architecture in src/init.c)

# The products that we will ensure are always built
products = [
    LibraryProduct("libXNNPACK", :libxnnpack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CPUInfo_jll", cpuinfo_build_version; compat=join(string.(cpuinfo_compat), ", ")),
    BuildDependency(PackageSpec("FP16_jll", v"0.0.20210320")),
    Dependency("PThreadPool_jll", pthreadpool_build_version; compat=join(string.(pthreadpool_compat), ", ")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"5",
    julia_compat="1.6")

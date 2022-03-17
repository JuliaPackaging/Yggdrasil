# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XNNPACK"
version = v"0.0.20200323"

cpuinfo_build_version = v"0.0.20200228"

cpuinfo_compat = [
    cpuinfo_build_version,
    v"0.0.20200522", # previously released
    v"0.0.20200612", # due to pytorch v1.6.0 - v1.7.1, e.g. https://github.com/pytorch/pytorch/tree/v1.6.0/third_party/cpuinfo @ 63b254577ed77a8004a9be6ac707f3dccc4e1fd9
]

pthreadpool_build_version = v"0.0.20200302"

pthreadpool_compat = [
    pthreadpool_build_version,
    v"0.0.20200616", # due to pytorch v1.6.0 - v1.7.1, e.g. https://github.com/pytorch/pytorch/tree/v1.6.0/third_party/pthreadpool @ 029c88620802e1361ccf41d1970bd5b07fd6b7bb
]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/XNNPACK.git", "1b354636b5942826547055252f3b359b54acff95"),
    DirectorySource("./bundled"),
    GitSource("https://github.com/pytorch/cpuinfo.git", "d5e37adf1406cf899d7d9ec1d317c47506ccb970"; unpack_target="clog"),
    GitSource("https://github.com/Maratyszcza/FP16.git", "ba1d31f5eed2eb4a69e4dea3870a68c7c95f998f"),
    GitSource("https://github.com/Maratyszcza/FXdiv.git", "f8c5354679ec2597792bc70a9e06eff50c508b9a"),
    GitSource("https://github.com/Maratyszcza/psimd.git", "88882f601f8179e1987b7e7cf4a8012c9080ad44"),
    GitSource("https://github.com/Maratyszcza/pthreadpool.git", "ebd50d0cfa3664d454ffdf246fcd228c3b370a11"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/XNNPACK
atomic_patch -p1 ../patches/xnnpack-disable-fast-math.patch
atomic_patch -p1 ../patches/xnnpack-pic.patch
atomic_patch -p1 ../patches/xnnpack-freebsd.patch
if [[ $target == aarch64-* ]]; then
    atomic_patch -p1 ../patches/xnnpack-disable-neon-fp16-arithmetic.patch
fi
mkdir build
cd build
# Omitted cmake define of CPUINFO_SOURCE_DIR as there is a patch for cpuinfo
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=$libdir \
    -DCLOG_SOURCE_DIR=$WORKSPACE/srcdir/clog/cpuinfo \
    -DFP16_SOURCE_DIR=$WORKSPACE/srcdir/FP16 \
    -DFXDIV_SOURCE_DIR=$WORKSPACE/srcdir/FXdiv \
    -DPSIMD_SOURCE_DIR=$WORKSPACE/srcdir/psimd \
    -DPTHREADPOOL_SOURCE_DIR=$WORKSPACE/srcdir/pthreadpool \
    -DXNNPACK_LIBRARY_TYPE=shared \
    -DXNNPACK_BUILD_TESTS=OFF \
    -DXNNPACK_BUILD_BENCHMARKS=OFF \
    ..
if [[ $target == *-w64-mingw32* ]]; then
    cd cpuinfo-source
        atomic_patch -p1 ../../../patches/cpuinfo-mingw-lowercase-windows-include.patch
    cd ..
fi
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
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms) # i686-Windows fails to link
filter!(p -> arch(p) != "powerpc64le", platforms) # PowerPC64LE is unsupported by XNNPACK (Unsupported architecture in src/init.c)

# The products that we will ensure are always built
products = [
    LibraryProduct("libXNNPACK", :libxnnpack),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CPUInfo_jll", cpuinfo_build_version; compat=join(string.(cpuinfo_compat), ", ")),
    Dependency("PThreadPool_jll", pthreadpool_build_version; compat=join(string.(pthreadpool_compat), ", ")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"5",
    julia_compat="1.6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "librealsense"
version = v"2.35.0"

# Collection of sources required to build librealsense
sources = [
    GitSource("https://github.com/IntelRealSense/librealsense.git",
              "8594d09f092347a8b3d832d14e4fb631140620c5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd librealsense/
mkdir build
cd build
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_EXAMPLES=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_GRAPHICAL_EXAMPLES=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_UNIT_TESTS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_WITH_OPENMP=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DENFORCE_METADATA=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_PYTHON_BINDINGS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_MATLAB_BINDINGS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_OPENNI2_BINDINGS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_NODEJS_BINDINGS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_CSHARP_BINDINGS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DENABLE_CCACHE=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_UNITY_BINDINGS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DFORCE_LIBUVC=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DFORCE_WINUSB_UVC=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DTRACE_API=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DHWM_OVER_XU=true"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_SHARED_LIBS=true"
CMAKE_FLAGS="${CMAKE_FLAGS} -DENABLE_ZERO_COPY=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_EASYLOGGINGPP=true"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_CV_EXAMPLES=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_CV_KINFU_EXAMPLE=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_PCL_EXAMPLES=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_WITH_TM2=true"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_WITH_CUDA=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_WITH_STATIC_CRT=true"
CMAKE_FLAGS="${CMAKE_FLAGS} -DBUILD_GLSL_EXTENSIONS=true"
cmake ${CMAKE_FLAGS} ..
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc = :glibc)
    Linux(:x86_64, libc = :glibc)
    Linux(:aarch64, libc = :glibc)
    Linux(:armv7l, libc = :glibc, call_abi = :eabihf)
    MacOS(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("librealsense2", :librealsense2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "libusb_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"7")

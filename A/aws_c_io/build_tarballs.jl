# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "aws_c_io"
version = v"0.26.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-io.git", "bfb0819d3906502483611ce832a5ec6b897c8421"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-c-io

# Patch for MinGW toolchain
find . -type f -exec sed -i -e 's/Windows.h/windows.h/g' \
     -e 's/WS2tcpip.h/ws2tcpip.h/g' \
     -e 's/WinSock2.h/winsock2.h/g' \
     -e 's/MSWSock.h/mswsock.h/g' \
     -e 's/Mstcpip.h/mstcpip.h/g' \
     '{}' \;
# Lowercase names for MinGW
sed -i -e 's/Secur32/secur32/g' -e 's/Crypt32/crypt32/g' CMakeLists.txt

install_license LICENSE NOTICE

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
cmake --build . -j${nproc} --target install
"""

sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libaws-c-io", :libaws_c_io),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("s2n_tls_jll"; compat="1.6.4", platforms=filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
    Dependency("aws_c_cal_jll"; compat="0.9.13"),
    Dependency("aws_c_common_jll"; compat="0.12.6"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

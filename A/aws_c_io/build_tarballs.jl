# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_c_io"
version = v"0.23.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-io.git", "1af325b54bba2e95a640a5be5ffe0b27e4ead79c"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

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
    Dependency("s2n_tls_jll"; compat="1.5.27", platforms=filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
    Dependency("aws_c_cal_jll"; compat="0.9.4"),
    Dependency("aws_c_common_jll"; compat="0.12.5"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

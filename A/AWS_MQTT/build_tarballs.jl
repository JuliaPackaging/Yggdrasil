# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AWS_MQTT"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-mqtt.git", "6168e32bf9f745dec40df633b78baa03420b7f83"),
    GitSource("https://github.com/awslabs/aws-lc.git", "11b50d39cf2378703a4ca6b6fee9d76a2e9852d1"),
    GitSource("https://github.com/aws/s2n-tls.git", "88c7ae4d3fd9b3e9e49fcecc9bee1ddb8099ae70"),
    GitSource("https://github.com/awslabs/aws-c-common.git", "68f28f8df258390744f3c5b460250f8809161041"),
    GitSource("https://github.com/awslabs/aws-c-cal.git", "001007e36dddc5da47b8c56d41bb63e5fa9328d7"),
    GitSource("https://github.com/awslabs/aws-c-io.git", "59b4225bb87021d44d7fd2509b54d7038f11b7e7"),
    GitSource("https://github.com/awslabs/aws-c-compression.git", "5fab8bc5ab5321d86f6d153b06062419080820ec"),
    GitSource("https://github.com/awslabs/aws-c-http.git", "3f8ffda541eab815646f739cef2b350d6e7d5406"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-lc

# Disable -Werror because there are... well... warnings
sed -i 's/-Werror//g' CMakeLists.txt

if [[ "${target}" == *-mingw* ]]; then
    # GetTickCount64 requires Windows Vista:
    # https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-gettickcount64
    export CXXFLAGS=-D_WIN32_WINNT=0x0600
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_STATIC_LIBS=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -GNinja \
    ..
ninja -j${nproc}
ninja install

cd $WORKSPACE/srcdir/s2n-tls
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	..
cmake --build . -j${nproc}
cmake --install .

cd $WORKSPACE/srcdir/aws-c-common
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	..
cmake --build . -j${nproc} --target install

cd $WORKSPACE/srcdir/aws-c-cal
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	..
cmake --build . -j${nproc} --target install

cd $WORKSPACE/srcdir/aws-c-io
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	..
cmake --build . -j${nproc} --target install

cd $WORKSPACE/srcdir/aws-c-compression
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	..
cmake --build . -j${nproc} --target install

cd $WORKSPACE/srcdir/aws-c-http
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=ON \
	-DBUILD_SHARED_LIBS=OFF \
	..
cmake --build . -j${nproc} --target install

cd $WORKSPACE/srcdir/aws-c-mqtt

# Patch the aws-c-mqtt CMakeLists.txt file so that we can build it as a shared library with static library dependencies
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mqtt_cmake.patch"

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_STATIC_LIBS=OFF \
	-DBUILD_SHARED_LIBS=ON \
	..
cmake --build . -j${nproc} --target install

install_license ${WORKSPACE}/srcdir/license/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libaws-c-mqtt", :libawsmqtt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # TODO: this is needed only for Windows, but it looks like filtering
    # platforms for `HostBuildDependency` is broken
    HostBuildDependency("NASM_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")

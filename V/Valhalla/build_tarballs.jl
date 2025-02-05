# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Valhalla"
version = v"3.5.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/valhalla/valhalla.git", "d377c8ace9ea88dfa989466258bf738b1080f22a"),
    DirectorySource("./bundled"),
    ArchiveSource("https://github.com/realjf/MacOSX-SDKs/releases/download/v0.0.1/MacOSX12.3.sdk.tar.xz",
                  "a511c1cf1ebfe6fe3b8ec005374b9c05e89ac28b3d4eb468873f59800c02b030"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/valhalla/

# Handle Mac SDK <10.14 errors
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports C++20
    pushd $WORKSPACE/srcdir/MacOSX12.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/*
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export MACOSX_DEPLOYMENT_TARGET=12.3
fi

git submodule update --init --recursive

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/protoc-find-exec.patch

if [[ "${target}" == *freebsd* ]]; then
    cd third_party/cpp-statsd-client
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cpp-statsd-client.patch
    cd ../../
fi

if [[ "${target}" == *freebsd* ]] || [[ "${target}" == *mingw* ]]; then
    # FreeBSD, Mingw don't seem to ship a lz4.pc file
    mv ${WORKSPACE}/srcdir/patches/liblz4.pc ${prefix}/lib/pkgconfig/
fi

mkdir build && cd build

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_PREFIX_PATH=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DENABLE_DATA_TOOLS=OFF
    -DENABLE_PYTHON_BINDINGS=OFF
    -DENABLE_BENCHMARKS=OFF
    -DENABLE_TESTS=OFF
    -DPROTOBUF_INCLUDE_DIRS=${includedir}
    -DPROTOBUF_LIBRARIES=${libdir}/libprotobuf.${dlext}
    -DPROTOBUF_PROTOC_LIBRARIES=${libdir}/libprotoc.${dlext}
    -DProtobuf_LITE_LIBRARIES=${libdir}/libprotobuf-lite.${dlext}
    -DENABLE_SERVICES=OFF
    -DENABLE_TOOLS=OFF
    -DENABLE_CCACHE=OFF
    -DENABLE_BENCHMARKS=OFF
    -DPROTOBUF_PROTOC_EXECUTABLE=${host_bindir}/protoc
    -DLOGGING_LEVEL=DEBUG
)

cmake "${CMAKE_FLAGS[@]}" ..

make -j${nproc}
make -j${nproc} install

install_license ../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Windows is blocked until pkg-config issues are figured out (https://github.com/valhalla/valhalla/issues/3931)
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libvalhalla", :libvalhalla),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.87.0")
    Dependency("GEOS_jll"; compat="3.13.1")
    Dependency("LibCURL_jll")
    Dependency("Lz4_jll")
    Dependency("protoc_jll"; compat="105.29.3")
    HostBuildDependency("protoc_jll")
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1", clang_use_lld=true)

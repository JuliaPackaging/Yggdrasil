# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Valhalla"
version = v"3.5.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/valhalla/valhalla.git", "d377c8ace9ea88dfa989466258bf738b1080f22a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/valhalla/

# Handle Mac SDK <10.12 errors
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.12
fi

git submodule update --init --recursive

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/protoc-find-exec.patch

if [[ "${target}" == *freebsd* ]]; then
    cd third_party/cpp-statsd-client
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cpp-statsd-client.patch
    cd ../../
fi

mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_DATA_TOOLS=OFF \
    -DENABLE_PYTHON_BINDINGS=OFF \
    -DENABLE_BENCHMARKS=OFF \
    -DENABLE_TESTS=OFF \
    -DPROTOBUF_INCLUDE_DIR=${includedir} \
    -DPROTOBUF_LIBRARY=${libdir}/libprotobuf.${dlext} \
    -DLZ4_INCLUDE_DIR=${includedir} \
    -DLZ4_LIBRARY=${libdir}/liblz4.${dlext} \
    -DENABLE_SERVICES=OFF \
    -DENABLE_TOOLS=OFF \
    -DENABLE_CCACHE=OFF \
    -DENABLE_BENCHMARKS=OFF \
    -DPROTOBUF_PROTOC_EXECUTABLE=${host_bindir}/protoc \
    -DLOGGING_LEVEL=DEBUG

make -j${nproc}
make -j${nproc} install

install_license ../LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Windows is blocked until pkg-config issues are figured out (https://github.com/valhalla/valhalla/issues/3931)
platforms = supported_platforms(; exclude=Sys.iswindows)
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
    Dependency("protoc_jll")
    HostBuildDependency("protoc_jll")
    Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")

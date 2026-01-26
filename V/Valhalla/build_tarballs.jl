# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

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

git submodule update --init --recursive

# Help cmake find protoc exec for host, protoc libs for target
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/protoc-find-exec.patch

# Improve compatibility with more recent CXX20 oriented gcc version
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix-template-id-cdtor-error.patch

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
    -DENABLE_SERVICES=OFF
    -DENABLE_TOOLS=ON
    -DENABLE_CCACHE=OFF
    -DENABLE_DATA_TOOLS=OFF
    -DENABLE_PYTHON_BINDINGS=OFF
    -DENABLE_BENCHMARKS=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_GDAL=OFF
    -DPROTOBUF_INCLUDE_DIRS=${includedir}
    -DPROTOBUF_LIBRARIES=${libdir}/libprotobuf.${dlext}
    -DPROTOBUF_PROTOC_LIBRARIES=${libdir}/libprotoc.${dlext}
    -DProtobuf_LITE_LIBRARIES=${libdir}/libprotobuf-lite.${dlext}
    -DPROTOBUF_PROTOC_EXECUTABLE=${host_bindir}/protoc
    -DLOGGING_LEVEL=DEBUG
    -DCMAKE_CXX_STANDARD=17
)

cmake "${CMAKE_FLAGS[@]}" ..

make -j${nproc}
make -j${nproc} install

install_license ../LICENSE.md
"""

# Install a newer SDK which supports C++20
sources, script = require_macos_sdk("12.3", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libvalhalla", :libvalhalla),
    ExecutableProduct("valhalla_service", :valhalla_service),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="protoc_jll", version="105.29.3"))
    Dependency("boost_jll"; compat="=1.87.0")
    Dependency("GEOS_jll"; compat="3.13.1")
    Dependency("LibCURL_jll"; compat="7.73,8")
    Dependency("Lz4_jll")
    Dependency("protoc_jll"; compat="105.29.3")
    Dependency("Zlib_jll")
    Dependency("OpenSSL_jll"; compat="3.0.16")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "onnxruntime"
version = v"1.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1"),
    ArchiveSource("https://github.com/protocolbuffers/protobuf/releases/download/v3.16.1/protoc-3.16.1-linux-x86_64.zip", "dffb7209d31b7e87e8e8ba2d5d869ceda5a5cea8883c4b13a726611a0dbd8a7c"; unpack_target = "protoc"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "a0c6db3cff65bd282f6ba4a57789e619c27e55203321aa08c023019fe9da50d7"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x86-$version.zip", "fd1680fa7248ec334efc2564086e9c5e0d6db78337b55ec32e7b666164bdb88c"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-osx-arm64-$version.tgz", "1dbf1b0aed50849a58ae74d6790c35aaffb2362eaff64a8c9bc6fc39c2545357")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ $target == *-w64-mingw32 || $target == aarch64-apple-darwin ]]; then
    if [[ $target == *-w64-mingw32 ]]; then
        if [[ $target == x86_64-w64-mingw32 ]]; then
            dist_name=onnxruntime-win-x64
        elif [[ $target == i686-w64-mingw32 ]]; then
            dist_name=onnxruntime-win-x86
        fi
        chmod 755 $dist_name*/lib/*
    elif [[ $target == aarch64-apple-darwin ]]; then
        dist_name=onnxruntime-osx-arm64
    fi

    mkdir -p $includedir $libdir
    cp -a $dist_name*/include/* $includedir
    cp -a $dist_name*/lib/* $libdir
    install_license $dist_name*/LICENSE
else
    cd onnxruntime
    git submodule update --init --recursive
    mkdir -p build
    cd build
    cmake $WORKSPACE/srcdir/onnxruntime/cmake \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DONNX_CUSTOM_PROTOC_EXECUTABLE=$WORKSPACE/srcdir/protoc/bin/protoc \
        -Donnxruntime_BUILD_SHARED_LIB=ON \
        -Donnxruntime_BUILD_UNIT_TESTS=OFF \
        -Donnxruntime_CROSS_COMPILING=ON \
        $CMAKE_EXTRA_ARGS
    make -j $nproc
    make install
    install_license $WORKSPACE/srcdir/onnxruntime/LICENSE
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
function platform_exclude_filter(p::Platform)
    libc(p) == "musl" ||
    p == Platform("i686", "Linux") ||
    Sys.isfreebsd(p)
end
platforms = supported_platforms(; exclude=platform_exclude_filter)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6")

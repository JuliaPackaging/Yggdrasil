# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime"
version = v"1.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "a0c6db3cff65bd282f6ba4a57789e619c27e55203321aa08c023019fe9da50d7"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x86-$version.zip", "fd1680fa7248ec334efc2564086e9c5e0d6db78337b55ec32e7b666164bdb88c"; unpack_target="onnxruntime-i686-w64-mingw32")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ $target == *-w64-mingw32* ]]; then
    chmod 755 onnxruntime-$target/onnxruntime-*/lib/*
    mkdir -p $includedir $libdir
    cp -av onnxruntime-$target/onnxruntime-*/include/* $includedir
    cp -av onnxruntime-$target/onnxruntime-*/lib/* $libdir
    install_license onnxruntime-$target/onnxruntime-*/LICENSE
else
    # Cross-compiling for aarch64-apple-darwin on x86_64 requires setting arch.: https://github.com/microsoft/onnxruntime/blob/v1.10.0/cmake/CMakeLists.txt#L186
    if [[ $target == aarch64-apple-darwin* ]]; then
        cmake_extra_args="-DCMAKE_OSX_ARCHITECTURES='arm64'"
    fi

    cd onnxruntime
    git submodule update --init --recursive
    mkdir -p build
    cd build
    cmake $WORKSPACE/srcdir/onnxruntime/cmake \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DONNX_CUSTOM_PROTOC_EXECUTABLE=$host_bindir/protoc \
        -Donnxruntime_BUILD_SHARED_LIB=ON \
        -Donnxruntime_BUILD_UNIT_TESTS=OFF \
        -Donnxruntime_DISABLE_RTTI=OFF \
        $cmake_extra_args
    make -j $nproc
    make install
    install_license $WORKSPACE/srcdir/onnxruntime/LICENSE
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
function platform_exclude_filter(p::Platform)
    libc(p) == "musl" ||
    p == Platform("i686", "Linux") || # No binary - and source build fails linking CXX shared library libonnxruntime.so
    Sys.isfreebsd(p)
end
platforms = supported_platforms(; exclude=platform_exclude_filter)
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec("protoc_jll", Base.UUID("c7845625-083e-5bbe-8504-b32d602b7110"), v"3.16.1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6")

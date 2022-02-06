# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "onnxruntime"
version = v"1.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "a0c6db3cff65bd282f6ba4a57789e619c27e55203321aa08c023019fe9da50d7"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x86-$version.zip", "fd1680fa7248ec334efc2564086e9c5e0d6db78337b55ec32e7b666164bdb88c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ $target == *-w64-mingw32* ]]; then
    if [[ $target == x86_64-w64-mingw32* ]]; then
        dist_name=onnxruntime-win-x64
    elif [[ $target == i686-w64-mingw32* ]]; then
        dist_name=onnxruntime-win-x86
    fi
    chmod 755 $dist_name*/lib/*
    mkdir -p $includedir $libdir
    cp -a $dist_name*/include/* $includedir
    cp -a $dist_name*/lib/* $libdir
    install_license $dist_name*/LICENSE
else
    # aarch64-apple-darwin fix, cf. https://github.com/microsoft/onnxruntime/issues/6573#issuecomment-900877035
    if [[ $target == aarch64-apple-darwin* ]]; then
        cmake_extra_defines=CMAKE_OSX_ARCHITECTURES='arm64'
    # Workaround for https://github.com/microsoft/onnxruntime/issues/2152
    elif [[ $target == arm-linux-gnueabihf* ]]; then
        cmake_extra_defines="onnxruntime_DEV_MODE=OFF"
    fi

    cd onnxruntime
    python3 tools/ci_build/build.py \
        --build \
        --build_dir $WORKSPACE/srcdir/onnxruntime/build \
        --build_shared_lib \
        --cmake_extra_defines \
            CMAKE_INSTALL_PREFIX=$prefix \
            CMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            onnxruntime_BUILD_UNIT_TESTS=OFF \
            $cmake_extra_defines \
        --config Release \
        --parallel $nproc \
        --path_to_protoc_exe $host_bindir/protoc \
        --skip_tests \
        --update
    cd build/Release
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

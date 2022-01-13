# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "onnxruntime"
version = v"1.10.0"

# Collection of sources required to complete build
source_sources = [
    GitSource("https://github.com/microsoft/onnxruntime.git", "0d9030e79888d1d5828730b254fedc53c7b640c1")
]

# Bash recipe for building across all platforms
source_script = raw"""
cd $WORKSPACE/srcdir

wget https://github.com/Kitware/CMake/releases/download/v3.22.1/cmake-3.22.1-linux-x86_64.sh
chmod u+x cmake-3.22.1-linux-x86_64.sh 
./cmake-3.22.1-linux-x86_64.sh --skip-license --include-subdir
CMAKE=`pwd`/cmake-3.22.1-linux-x86_64/bin/cmake

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.16.1/protoc-3.16.1-linux-x86_64.zip
unzip -d protoc protoc-3.16.1-linux-x86_64.zip

cd onnxruntime/

git submodule update --init --recursive

mkdir -p build
cd build
$CMAKE $WORKSPACE/srcdir/onnxruntime/cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DONNX_CUSTOM_PROTOC_EXECUTABLE=$WORKSPACE/srcdir/protoc/bin/protoc \
    -Donnxruntime_BUILD_SHARED_LIB=ON \
    -Donnxruntime_BUILD_UNIT_TESTS=OFF \
    -Donnxruntime_CROSS_COMPILING=ON
make -j $nproc
make install
install_license $WORKSPACE/srcdir/onnxruntime/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
binaries = Dict(
    Platform("aarch64", "macOS") => "onnxruntime-osx-arm64-$version.tgz",
    Platform("x86_64", "Windows") => "onnxruntime-win-x64-$version.zip",
    Platform("i686", "Windows") => "onnxruntime-win-x86-$version.zip",
)
function source_platform_exclude_filter(p::Platform)
    libc(p) == "musl" ||
    p == Platform("i686", "Linux") ||
    p == Platform("x86_64", "FreeBSD") ||
    p in keys(binaries)
end
source_platforms = supported_platforms(; exclude=source_platform_exclude_filter)
source_platforms = expand_cxxstring_abis(source_platforms)
@info "Re-packaging binaries for:\n$(join(keys(binaries), "\n"))"
@info "Building binaries for:\n$(join(source_platforms, "\n"))"

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libonnxruntime", "onnxruntime"], :libonnxruntime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

for (platform, dist_name) in binaries
    binary_sources = []
    binary_script = """
    cd \$WORKSPACE/srcdir
    
    wget https://github.com/microsoft/onnxruntime/releases/download/v$version/$dist_name
    if [[ $dist_name == *.zip ]]; then
        unzip $dist_name
    else
        tar xfz $dist_name
    fi
    mkdir -p \$includedir \$libdir
    cp -a onnxruntime*/include/* \$includedir
    if [[ \${target} == *w64* ]]; then
        chmod 755 onnxruntime*/lib/*
    fi
    cp -a onnxruntime*/lib/* \$libdir
    install_license onnxruntime*/LICENSE
    """
    binary_platforms = [platform]
    build_tarballs(ARGS, name, version, binary_sources, binary_script, binary_platforms, products, dependencies;
        preferred_gcc_version = v"8",
        julia_compat = "1.6")
end

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, source_sources, source_script, source_platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat = "1.6")

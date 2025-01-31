# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZXing_CPP"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zxing-cpp/zxing-cpp.git", "d6068bcebeb8fd9f0d35a99b00d202be86a14dbe"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/13.3/MacOSX13.3.sdk.tar.xz", "e5d0f958a079106234b3a840f93653308a76d3dcea02d3aa8f2841f8df33050c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zxing-cpp/
git submodule update --init

if [[ "$target" == *-apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX13.3.sdk
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$target/$target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
    export MACOSX_DEPLOYMENT_TARGET=10.13
fi

# To-Do: remove it when https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/407 merged
if [[ "$target" == riscv64-linux-gnu ]]; then
    export LDFLAGS="-lstdc++"
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DZXING_READERS=ON \
    -DZXING_WRITERS=NEW \
    -DZXING_USE_BUNDLED_ZINT=ON \
    -DZXING_C_API=ON \
    -DZXING_EXPERIMENTAL_API=ON
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# aarch64-unknown-freebsd failed with "error: reference to '__builtin_va_list' is ambiguous"
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libZXing", :libZXing)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")

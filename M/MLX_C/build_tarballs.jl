# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MLX_C"
version = v"0.0.11"

sources = [
    GitSource("https://github.com/ml-explore/mlx-c.git", "126253627b95a0803273f44655fdaf5e7be4fbe1"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49"),
    DirectorySource("./bundled"),
]

script = raw"""
# MLX hack
cd $includedir
mv mlx/io.h mlx/io.h.bak
cp mlx/io.h.bak mlx/io.h
mv mlx/backend/metal/metal.h mlx/backend/metal/metal.h.bak
cp mlx/backend/metal/metal.h.bak mlx/backend/metal/metal.h
atomic_patch -p1 $WORKSPACE/srcdir/patches/mlx-std_unordered_map.patch

if [[ "$target" == *-apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    sed -i "s!/opt/$bb_target/$bb_target/sys-root!$apple_sdk_root!" /opt/bin/$bb_full_target/$target-clang++
fi

cd $WORKSPACE/srcdir/mlx-c

atomic_patch -p1 ../patches/cmake-win32.patch

if [[ "$target" == *-w64-mingw32* ]]; then
    atomic_patch -p1 ../patches/cmake-win32-io.patch
fi

export MACOSX_DEPLOYMENT_TARGET=13.3

cmake \
    -B build \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -DMLX_C_BUILD_EXAMPLES=OFF \
    -DMLX_C_USE_SYSTEM_MLX=ON \
    -G Ninja
cmake --build build --parallel $nproc
cmake --install build
install_license LICENSE

# Restore MLX hack
cd $includedir
rm mlx/io.h
mv mlx/io.h.bak mlx/io.h
rm mlx/backend/metal/metal.h
mv mlx/backend/metal/metal.h.bak mlx/backend/metal/metal.h
"""

platforms = supported_platforms()
filter!(!Sys.isfreebsd, platforms) # No MLX_jll artifact for FreeBSD
platforms = expand_cxxstring_abis(platforms)

products = Product[
    FileProduct("include/mlx/c/mlx.h", :mlx_c_mlx_h),
    LibraryProduct(["libmlxc", "mlxc"], :libmlxc),
]

dependencies = [
    BuildDependency("dlfcn_win32_jll"; platforms = filter(Sys.iswindows, platforms)),
    Dependency("MLX_jll"; compat = "0.20")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.9",
    preferred_gcc_version = v"10", # arm_bf16.h
)

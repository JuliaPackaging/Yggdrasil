sources = [
    GitSource("https://github.com/flann-lib/flann.git", "c50f296b0b27e14667d272b37acc63f949b305c4"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
# Lz4 *-w64-mingw32 artifacts have pkgconfig in $prefix/bin, instead of $prefix/lib
if [[ "$target" == *-w64-mingw32 ]]; then
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$bindir/pkgconfig

# Lz4 *-unknown-freebsd* artifacts have no pkgconfig
elif [[ "$target" == *-unknown-freebsd* ]]; then
    install -D -m 644 -v ${WORKSPACE}/srcdir/lz4/liblz4.pc $libdir/pkgconfig/liblz4.pc
fi

cd $WORKSPACE/srcdir/flann

cmake_extra_args=()

if [[ $bb_full_target == *cuda* ]]; then
    export CUDA_PATH="$prefix/cuda"
    cmake_extra_args+=(
        -DBUILD_CUDA_LIB=ON
        -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH
        -DCUDA_NVCC_FLAGS=-std=c++14
    )
fi

cmake \
    -B build \
    -DBUILD_C_BINDINGS=ON \
    -DBUILD_DOC=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_MATLAB_BINDINGS=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF \
    -DBUILD_TESTS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -G Ninja \
    ${cmake_extra_args[@]}

cmake --build build --parallel ${nproc}
cmake --install build

if [[ "$target" == *-unknown-freebsd* ]]; then
    rm -rf $libdir/pkgconfig
fi
"""

products = [
    LibraryProduct("libflann_cpp", :libflann_cpp),
    LibraryProduct("libflann", :libflann)
]

dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll", platforms = filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll", platforms = filter(Sys.isbsd, platforms)),

    Dependency("Lz4_jll"),
]

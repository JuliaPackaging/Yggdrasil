using BinaryBuilder, Pkg

name = "llama_cpp"
version = v"0.0.13"  # fake version number

# url = "https://github.com/ggerganov/llama.cpp"
# description = "Port of Facebook's LLaMA model in C/C++"

# Supported accelerators
# - MacOS: CPU, Metal (Apple Silicon), Accelerate (Intel)
# - all others: CPU
# - on x86_64 and i686 we assume these arch extensions are available
#   - avx (LLAMA_AVX)
#   - avx2 (LLAMA_AVX2)
#   - f16c (LLAMA_F16C)
#   - fma (LLAMA_FMA)

# TODO
# - missing build options
#   - BLAS (LLAMA_BLAS)
#   - CUDA/CuBLAS (LLAMA_CUBLAS)
#   - OpenCL/CLBLAST (LLAMA_CLBLAST)

# Build notes and failures
# - k_quants disabled for armv{6,7}-linux due to compile errors
# - k_quants fails to compile on aarch64-linux for gcc-9 and below
# - missing arch: powerpc64le (code tests for __POWER9_VECTOR__)
# - fails on i686-w64-mingw32
#   /workspace/srcdir/llama.cpp/examples/main/main.cpp:249:81: error: invalid static_cast from type ‘main(int, char**)::<lambda(DWORD)>’ to type ‘PHANDLER_ROUTINE’ {aka ‘int (__attribute__((stdcall)) *)(long unsigned int)’}

# versions: fake_version to github_version mapping
#
# fake_version    date_released    github_version    github_url
# 0.0.1           2023-03-20       master-074bea2    https://github.com/ggerganov/llama.cpp/releases/tag/master-074bea2
# 0.0.2           2023-03-21       master-8cf9f34    https://github.com/ggerganov/llama.cpp/releases/tag/master-8cf9f34
# 0.0.3           2023-03-22       master-d5850c5    https://github.com/ggerganov/llama.cpp/releases/tag/master-d5850c5
# 0.0.4           2023-03-25       master-1972616    https://github.com/ggerganov/llama.cpp/releases/tag/master-1972616
# 0.0.5           2023-03-30       master-3bcc129    https://github.com/ggerganov/llama.cpp/releases/tag/master-3bcc129
# 0.0.6           2023-04-03       master-437e778    https://github.com/ggerganov/llama.cpp/releases/tag/master-437e778
# 0.0.6+1         2023-04-16       master-47f61aa    https://github.com/ggerganov/llama.cpp/releases/tag/master-47f61aa
# 0.0.7           2023-04-24       master-c4fe84f    https://github.com/ggerganov/llama.cpp/releases/tag/master-c4fe84f
# 0.0.8           2023-05-02       master-e216aa0    https://github.com/ggerganov/llama.cpp/releases/tag/master-e216aa0
# 0.0.9           2023-05-19       master-6986c78    https://github.com/ggerganov/llama.cpp/releases/tag/master-6986c78
# 0.0.10          2023-05-19       master-2d5db48    https://github.com/ggerganov/llama.cpp/releases/tag/master-2d5db48
# 0.0.11          2023-06-13       master-9254920    https://github.com/ggerganov/llama.cpp/releases/tag/master-9254920
# 0.0.12          2023-07-24       master-41c6741    https://github.com/ggerganov/llama.cpp/releases/tag/master-41c6741
# 0.0.13          2023-07-29       master-11f3ca0    https://github.com/ggerganov/llama.cpp/releases/tag/master-11f3ca0

sources = [
    GitSource("https://github.com/ggerganov/llama.cpp.git",
              "11f3ca06b8c66b0427aab0a472479da22553b472"),
]

script = raw"""
cd $WORKSPACE/srcdir/llama.cpp*

# remove compiler flags forbidden in BinaryBuilder
sed -i -e 's/-funsafe-math-optimizations//g' CMakeLists.txt

EXTRA_CMAKE_ARGS=
if [[ "${target}" == *-linux-* ]]; then
    # otherwise we have undefined reference to `clock_gettime' when
    # linking the `main' example program
    EXTRA_CMAKE_ARGS='-DCMAKE_EXE_LINKER_FLAGS="-lrt"'
fi

# compilation errors using k_quants on armv{6,7}l-linux-*
if [[ "${proc_family}" == "arm" && "${nbits}" == 32 ]]; then
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DLLAMA_K_QUANTS=OFF"
else
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DLLAMA_K_QUANTS=ON"
fi

# Use Metal on Apple Silicon
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DLLAMA_METAL=ON"
fi

mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=ON \
    -DLLAMA_NATIVE=OFF \
    -DLLAMA_ACCELERATE=ON \
    -DLLAMA_AVX=ON \
    -DLLAMA_AVX2=ON \
    -DLLAMA_F16C=ON \
    -DLLAMA_FMA=ON \
    -DLLAMA_BLAS=OFF \
    -DLLAMA_CUBLAS=OFF \
    -DLLAMA_CLBLAST=OFF \
    $EXTRA_CMAKE_ARGS
make -j${nproc}

make install

# install header files
for hdr in ../*.h; do
    install -Dvm 644 "${hdr}" "${includedir}/$(basename "${hdr}")"
done

install_license ../LICENSE
"""

platforms = supported_platforms(; exclude = p -> arch(p) == "powerpc64le" || (arch(p) == "i686" && Sys.iswindows(p)))
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("baby-llama", :baby_llama),
    ExecutableProduct("benchmark", :benchmark),
    ExecutableProduct("embd-input-test", :embd_input_test),
    ExecutableProduct("embedding", :embedding),
    ExecutableProduct("main", :main),
    ExecutableProduct("perplexity", :perplexity),
    ExecutableProduct("quantize", :quantize),
    ExecutableProduct("quantize-stats", :quantize_stats),
    ExecutableProduct("save-load-state", :save_load_state),
    ExecutableProduct("server", :server),
    ExecutableProduct("simple", :simple),
    ExecutableProduct("train-text-from-scratch", :train_text_from_scratch),
    LibraryProduct("libembdinput", :libembdinput),
    LibraryProduct("libggml_shared", :libggml),
    LibraryProduct("libllama", :libllama),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"10")

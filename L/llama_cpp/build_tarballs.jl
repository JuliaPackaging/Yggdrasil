using BinaryBuilder, Pkg

name = "llama_cpp"
version = v"0.0.17"  # fake version number

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
# - k_quants disabled for armv{6,7}-linux due to compile errors -- re-enabled as LLAMA_K_QUANTS option is no longer available
# - k_quants fails to compile on aarch64-linux for gcc-9 and below
# - missing arch: powerpc64le (code tests for __POWER9_VECTOR__)
# - fails on i686-w64-mingw32
#   /workspace/srcdir/llama.cpp/examples/main/main.cpp:249:81: error: invalid static_cast from type ‘main(int, char**)::<lambda(DWORD)>’ to type ‘PHANDLER_ROUTINE’ {aka ‘int (__attribute__((stdcall)) *)(long unsigned int)’}
# - removed armv{6,7} specific CMAKE ARGS as the flag `LLAMA_K_QUANTS` is no longer available
# - removed Product "embd_input_test" as it's no longer part of the project
# - removed Library "libembdinput" as it's no longer part of the project
# - disabled METAL (LLAMA_METAL=OFF) on Intel-based MacOS as it's not supported (supported on Apple Silicon only)
# - temporary disabled armv{6,7} builds due to compile errors (missing vld1q_u8_x2, vqtbl1q_u8, uint8x16_t), issue: https://github.com/ggerganov/llama.cpp/issues/5748

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
# 0.0.14          2024-01-04       b1767             https://github.com/ggerganov/llama.cpp/releases/tag/b1767
# 0.0.15          2024-01-09       b1796             https://github.com/ggerganov/llama.cpp/releases/tag/b1796
# 0.0.16          2024-03-10       b2382             https://github.com/ggerganov/llama.cpp/releases/tag/b2382
# 0.0.17          2024-12-20       b4371             https://github.com/ggerganov/llama.cpp/releases/tag/b4371

sources = [
    GitSource("https://github.com/ggerganov/llama.cpp.git", "eb5c3dc64bd967f2e23c87d9dec195f45468de60"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

script = raw"""
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `std::filesystem`
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -a usr/* "/opt/${target}/${target}/sys-root/usr/"
    cp -a System "/opt/${target}/${target}/sys-root/"
    popd
fi

cd $WORKSPACE/srcdir/llama.cpp*

# remove compiler flags forbidden in BinaryBuilder
sed -i -e 's/-funsafe-math-optimizations//g' CMakeLists.txt

EXTRA_CMAKE_ARGS=()
if [[ "${target}" == *-linux-* ]]; then
    # otherwise we have undefined reference to `clock_gettime' when
    # linking the `main' example program
    EXTRA_CMAKE_ARGS+=(-DCMAKE_EXE_LINKER_FLAGS="-lrt")
fi

# Disable Metal on Intel Apple platforms
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    EXTRA_CMAKE_ARGS+=(-DGGML_METAL=OFF)
fi

cmake -Bbuild -GNinja \
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
    "${EXTRA_CMAKE_ARGS[@]}"
cmake --build build
cmake --install build
install_license LICENSE
"""

platforms = supported_platforms()

# aarch64-linux-musl:
# /workspace/srcdir/llama.cpp/ggml/src/ggml-cpu/ggml-cpu.c:2398:53: error: ‘HWCAP_ASIMDDP’ undeclared (first use in this function); did you mean ‘HWCAP_ASIMDHP’?
filter!(p -> !(Sys.islinux(p) && arch(p) == "aarch64" && libc(p) == "musl"), platforms)

platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("llama-batched", :llama_batched),
    ExecutableProduct("llama-batched-bench", :llama_batched_bench),
    ExecutableProduct("llama-bench", :llama_bench),
    ExecutableProduct("llama-cli", :llama_cli),
    ExecutableProduct("llama-convert-llama2c-to-ggml", :llama_convert_llama2c_to_ggml),
    ExecutableProduct("llama-cvector-generator", :llama_cvector_generator),
    ExecutableProduct("llama-embedding", :llama_embedding),
    ExecutableProduct("llama-eval-callback", :llama_eval_callback),
    ExecutableProduct("llama-export-lora", :llama_export_lora),
    # ExecutableProduct("llama-gbnf-validator", :llama_gbnf_validator),   # not built on Windows
    ExecutableProduct("llama-gen-docs", :llama_gen_docs),
    ExecutableProduct("llama-gguf", :llama_gguf),
    ExecutableProduct("llama-gguf-hash", :llama_gguf_hash),
    ExecutableProduct("llama-gguf-split", :llama_gguf_split),
    ExecutableProduct("llama-gritlm", :llama_gritlm),
    ExecutableProduct("llama-imatrix", :llama_imatrix),
    ExecutableProduct("llama-infill", :llama_infill),
    ExecutableProduct("llama-llava-cli", :llama_llava_cli),
    ExecutableProduct("llama-lookahead", :llama_lookahead),
    ExecutableProduct("llama-lookup", :llama_lookup),
    ExecutableProduct("llama-lookup-create", :llama_lookup_create),
    ExecutableProduct("llama-lookup-merge", :llama_lookup_merge),
    ExecutableProduct("llama-lookup-stats", :llama_lookup_stats),
    ExecutableProduct("llama-minicpmv-cli", :llama_minicpmv_cli),
    ExecutableProduct("llama-parallel", :llama_parallel),
    ExecutableProduct("llama-passkey", :llama_passkey),
    ExecutableProduct("llama-perplexity", :llama_perplexity),
    ExecutableProduct("llama-quantize", :llama_quantize),
    # ExecutableProduct("llama-quantize-stats", :llama_quantize_stats),   # not built on Windows
    ExecutableProduct("llama-qwen2vl-cli", :llama_qwen2vl_cli),
    ExecutableProduct("llama-retrieval", :llama_retrieval),
    ExecutableProduct("llama-run", :llama_run),
    ExecutableProduct("llama-save-load-state", :llama_save_load_state),
    ExecutableProduct("llama-server", :llama_server),
    ExecutableProduct("llama-simple", :llama_simple),
    ExecutableProduct("llama-simple-chat", :llama_simple_chat),
    ExecutableProduct("llama-speculative", :llama_speculative),
    ExecutableProduct("llama-speculative-simple", :llama_speculative_simple),
    ExecutableProduct("llama-tokenize", :llama_tokenize),
    ExecutableProduct("llama-tts", :llama_tts),

    LibraryProduct(["libggml-base", "ggml-base"], :libggml_base),
    LibraryProduct(["libggml-cpu", "ggml-cpu"], :libggml_cpu),
    LibraryProduct(["libggml", "ggml"], :libggml),
    LibraryProduct("libllama", :libllama),
    LibraryProduct("libllava_shared", :libllava_shared),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")

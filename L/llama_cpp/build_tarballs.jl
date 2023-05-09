using BinaryBuilder, Pkg

name = "llama_cpp"
version = v"0.0.8"  # fake version number

# url = "https://github.com/ggerganov/llama.cpp"
# description = "Port of Facebook's LLaMA model in C/C++"

# NOTES
# - missing arch: powerpc64le (code tests for __POWER9_VECTOR__)
# - fails on i686-w64-mingw32
#   /workspace/srcdir/llama.cpp/examples/main/main.cpp:249:81: error: invalid static_cast from type ‘main(int, char**)::<lambda(DWORD)>’ to type ‘PHANDLER_ROUTINE’ {aka ‘int (__attribute__((stdcall)) *)(long unsigned int)’}
# - on x86_64 and i686 we assume these arch extensions are available
#   - avx (LLAMA_AVX)
#   - avx2 (LLAMA_AVX2)
#   - f16c (LLAMA_F16C)
#   - fma (LLAMA_FMA)
# - on macos the accelerate framework is used
# - missing build options (build multiple jlls from a common build script?)
#   - OpenBLAS (LLAMA_OPENBLAS)
#   - CUDA/CuBLAS (LLAMA_CUBLAS)
#   - OpenCL/CLBLAST (LLAMA_CLBLAST)

# versions: fake_version to github_version mapping
#
# fake_version    date_released    github_version    github_url
# 0.0.1           20.03.2023       master-074bea2    https://github.com/ggerganov/llama.cpp/releases/tag/master-074bea2
# 0.0.2           21.03.2023       master-8cf9f34    https://github.com/ggerganov/llama.cpp/releases/tag/master-8cf9f34
# 0.0.3           22.03.2023       master-d5850c5    https://github.com/ggerganov/llama.cpp/releases/tag/master-d5850c5
# 0.0.4           25.03.2023       master-1972616    https://github.com/ggerganov/llama.cpp/releases/tag/master-1972616
# 0.0.5           30.03.2023       master-3bcc129    https://github.com/ggerganov/llama.cpp/releases/tag/master-3bcc129
# 0.0.6           03.04.2023       master-437e778    https://github.com/ggerganov/llama.cpp/releases/tag/master-437e778
# 0.0.6+1         16.04.2023       master-47f61aa    https://github.com/ggerganov/llama.cpp/releases/tag/master-47f61aa
# 0.0.7           24.04.2023       master-c4fe84f    https://github.com/ggerganov/llama.cpp/releases/tag/master-c4fe84f
# 0.0.8           02.05.2023       master-e216aa0    https://github.com/ggerganov/llama.cpp/releases/tag/master-e216aa0

sources = [
    GitSource("https://github.com/ggerganov/llama.cpp.git",
              "e216aa04633892b972d013719e38b59fd4917341"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/llama.cpp*

# remove -march=native from cmake files
atomic_patch -p1 ../patches/cmake-remove-compiler-flags-forbidden-in-bb.patch

EXTRA_CMAKE_ARGS=
if [[ "${target}" == *-linux-* ]]; then
    # otherwise we have undefined reference to `clock_gettime' when
    # linking the `main' example program
    EXTRA_CMAKE_ARGS='-DCMAKE_EXE_LINKER_FLAGS="-lrt"'
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
    -DLLAMA_OPENBLAS=OFF \
    -DLLAMA_CUBLAS=OFF \
    -DLLAMA_CLBLAST=OFF \
    $EXTRA_CMAKE_ARGS
make -j${nproc}

# `make install` doesn't work (2023.03.21)
# install executables
for prg in benchmark embedding main perplexity q8dot quantize quantize-stats save-load-state vdot; do
    install -Dvm 755 "./bin/${prg}${exeext}" "${bindir}/${prg}${exeext}"
done
# install libs
for lib in libllama; do
    if [[ "${target}" == *-w64-mingw32* ]]; then
        install -Dvm 755 "./bin/${lib}.${dlext}" "${libdir}/${lib}.${dlext}"
    else
        install -Dvm 755 "./${lib}.${dlext}" "${libdir}/${lib}.${dlext}"
    fi
done
# install header files
for hdr in llama.h ggml.h; do
    install -Dvm 644 "../${hdr}" "${includedir}/${hdr}"
done

install_license ../LICENSE
"""

platforms = supported_platforms(; exclude = p -> arch(p) == "powerpc64le" || (arch(p) == "i686" && Sys.iswindows(p)))
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("benchmark", :benchmark),
    ExecutableProduct("embedding", :embedding),
    ExecutableProduct("main", :main),
    ExecutableProduct("perplexity", :perplexity),
    ExecutableProduct("q8dot", :q8dot),
    ExecutableProduct("quantize", :quantize),
    ExecutableProduct("quantize-stats", :quantize_stats),
    ExecutableProduct("save-load-state", :save_load_state),
    ExecutableProduct("vdot", :vdot),
    LibraryProduct("libllama", :libllama),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8")

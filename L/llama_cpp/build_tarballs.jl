using BinaryBuilder, Pkg

name = "llama_cpp"
version = v"0.0.3"  # fake version number

# url = "https://github.com/ggerganov/llama.cpp"
# description = "Port of Facebook's LLaMA model in C/C++"

# TODO
# - i686, x86_64, aarch64 build
#   missing architectures: powerpc64le, armv6l, arm7vl

# versions: fake_version to github_version mapping
#
# fake_version    date_released    github_version    github_url
# 0.0.1           20.03.2023       master-074bea2    https://github.com/ggerganov/llama.cpp/releases/tag/master-074bea2
# 0.0.2           21.03.2023       master-8cf9f34    https://github.com/ggerganov/llama.cpp/releases/tag/master-8cf9f34
# 0.0.3           22.03.2023       master-d5850c5    https://github.com/ggerganov/llama.cpp/releases/tag/master-d5850c5

sources = [
    # 2023.03.22, https://github.com/ggerganov/llama.cpp/releases/tag/master-d5850c5
    # fake version = 0.0.3
    GitSource("https://github.com/ggerganov/llama.cpp.git",
              "d5850c53ca179b9674b98f35d359763416a3cc11"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/llama.cpp*

atomic_patch -p1 ../patches/cmake-remove-mcpu-native.patch

EXTRA_CMAKE_ARGS=
if [[ "${target}" == *-linux-* ]]; then
    EXTRA_CMAKE_ARGS='-DCMAKE_EXE_LINKER_FLAGS="-lrt"'
fi

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLAMA_NATIVE=OFF \
    $EXTRA_CMAKE_ARGS
make -j${nproc}

# `make install` doesn't work (2023.03.21)
# make install
for prg in main quantize; do
    install -Dvm 755 "./bin/${prg}${exeext}" "${bindir}/${prg}${exeext}"
done

install_license ../LICENSE
"""

platforms = supported_platforms(; exclude = p -> arch(p) ∉ ["i686", "x86_64", "aarch64"])
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("main", :main),
    ExecutableProduct("quantize", :quantize),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"8.1.0")

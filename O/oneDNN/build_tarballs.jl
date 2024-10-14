using BinaryBuilder, Pkg

name = "oneDNN"
version = v"3.5.3"

sources = [
    GitSource("https://github.com/oneapi-src/OneDNN", "66f0cb9eb66affd2da3bf5f8d897376f04aae6af"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/OneDNN

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/strnlen_s_windows.patch
fi

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
CMAKE_FLAGS+=(-DONEDNN_CPU_RUNTIME=OMP)
# TODO: Enable this if we need GPU support. For now, we only need CPU support
CMAKE_FLAGS+=(-DONEDNN_GPU_RUNTIME=NONE)
CMAKE_FLAGS+=(-DONEDNN_LIBRARY_TYPE=SHARED)
# Turn off stuff we don't need
CMAKE_FLAGS+=(-DONEDNN_BUILD_EXAMPLES=OFF)
CMAKE_FLAGS+=(-DONEDNN_BUILD_TESTS=OFF)
CMAKE_FLAGS+=(-DONEDNN_ENABLE_GRAPH_DUMP=OFF)
# See https://oneapi-src.github.io/oneDNN/dev_guide_build.html#gcc-targeting-aarch64-on-x64-host
if [[ "${target}" == aarch64* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_SYSTEM_PROCESSOR=AARCH64)
fi

cmake -B build ${CMAKE_FLAGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

# oneDNN supports 64 bit platforms only
filter!(p -> nbits(p) == 64, platforms)

# oneDNN fails due to unrecognized argument `-mcpu=native`
filter!(p -> arch(p) != "powerpc64le", platforms)

# oneDNN support for aarch64 is experimental and we fail to build on musl
filter!(p -> arch(p) != "aarch64" || libc(p) != "musl", platforms)

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct(["libdnnl", "dnnl"], :libdnnl),
]

dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")

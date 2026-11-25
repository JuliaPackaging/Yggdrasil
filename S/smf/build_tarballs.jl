# BinaryBuilder.jl recipe for smf_jll (Yggdrasil: S/smf/build_tarballs.jl)
using BinaryBuilder, Pkg

name = "smf"
version = v"0.2.0"

sources = [
    GitSource("https://github.com/danlil240/opt_solver.git",
              "31348d9da6dfcc854703fcfd1434f32a798712fb"),
    FileSource("https://github.com/joseluisq/MacOSX-SDKs/releases/download/15.0/MacOSX15.0.sdk.tar.xz",
               "9df0293776fdc8a2060281faef929bf2fe1874c1f9368993e7a4ef87b1207f98"),
]

script = raw"""
if [[ "${target}" == *-apple-darwin* ]]; then
    # Use MacOSX15.0.sdk for full C++20 libc++ support (std::bit_cast, std::span, std::atomic_ref).
    tar -xf "${WORKSPACE}/srcdir/MacOSX15.0.sdk.tar.xz" -C "${WORKSPACE}/srcdir"
    apple_sdk_root="${WORKSPACE}/srcdir/MacOSX15.0.sdk"
    sed -i "s!/opt/${target}/${target}/sys-root!${apple_sdk_root}!" "${CMAKE_TARGET_TOOLCHAIN}"
    sed -i "s!/opt/${target}/${target}/sys-root!${apple_sdk_root}!" /opt/bin/${bb_full_target}/${target}-clang*
    export MACOSX_DEPLOYMENT_TARGET=15.0
fi

cd $WORKSPACE/srcdir/opt_solver

if [[ "${target}" == *-mingw* ]]; then
    # Older MinGW-w64 winnt.h lacks PROCESSOR_RELATIONSHIP::EfficiencyClass.
    sed -i 's/rec->Processor.EfficiencyClass/0/' solver/src/parallel/thread_plan.cpp
fi

# Let BinaryBuilder's compiler wrappers select the target microarchitecture
# (do not force x86-64-v3 on generic x86_64 platforms).
# -D_GNU_SOURCE exposes siginfo_t in glibc 2.17 <signal.h> under METIS's -std=c99.
cmake -S solver -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-D_GNU_SOURCE" \
    -DSMF_USE_MKL=OFF \
    -DSMF_USE_SUITESPARSE_AMD=ON \
    -DSMF_USE_METIS=ON \
    -DSMF_VENDORED_METIS=ON \
    -DSMF_BUILD_C_API=ON \
    -DSMF_BUILD_MA97_PLUGIN=ON \
    -DSMF_BUILD_TESTS=OFF \
    -DSMF_BUILD_BENCHMARKS=OFF \
    -DBLAS_LIBRARIES="-L${libdir} -lopenblas" \
    -DLAPACK_LIBRARIES="-L${libdir} -lopenblas" \
    -DSMF_MARCH=none

cmake --build build -j ${nproc}
cmake --install build

install_license LICENSE
install_license solver/third_party/LICENSE-Apache-2.0.txt
install_license solver/third_party/metis/LICENSE
install_license solver/third_party/gklib/LICENSE.txt
"""

platforms = expand_cxxstring_abis(supported_platforms(; exclude=p -> arch(p) == "i686" || Sys.isfreebsd(p)))

products = [
    LibraryProduct("libsmf_c", :libsmf_c),
    LibraryProduct("libsmf_ma97", :libsmf_ma97),
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("SuiteSparse32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isapple, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"11")

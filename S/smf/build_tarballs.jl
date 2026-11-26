using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "smf"
version = v"0.2.1"

sources = [
    GitSource("https://github.com/danlil240/opt_solver.git",
              "8ffa88d29b6ef82cd613ca3c2486e113f98da895"; tag="v$(version)"),
]

script = raw"""
cd $WORKSPACE/srcdir/opt_solver

# Let BinaryBuilder's compiler wrappers select the target microarchitecture
# (do not force x86-64-v3 on generic x86_64 platforms).
cmake -S solver -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSMF_USE_MKL=OFF \
    -DSMF_USE_SUITESPARSE_AMD=ON \
    -DSMF_USE_METIS=ON \
    -DSMF_VENDORED_METIS=ON \
    -DSMF_BUILD_C_API=ON \
    -DSMF_BUILD_MA97_PLUGIN=ON \
    -DSMF_INSTALL_STATIC_LIBS=OFF \
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

# libc++ with C++20's std::bit_cast and std::span
sources, script = require_macos_sdk("15.0", sources, script)

platforms = expand_cxxstring_abis(supported_platforms(; exclude=p -> arch(p) == "i686" || Sys.isfreebsd(p)))

products = [
    LibraryProduct("libsmf_c", :libsmf_c),
    LibraryProduct("libsmf_ma97", :libsmf_ma97),
]

dependencies = [
    Dependency("OpenBLAS32_jll"; compat="0.3.34"),
    # 7.x installs libamd.so.3 and needs Julia 1.11
    Dependency("SuiteSparse32_jll"; compat="7.12.1"),
    # libstdc++ and libgomp. Julia 1.11 ships 1.1.1; build against 1.1.2,
    # the oldest release with a riscv64 build
    Dependency("CompilerSupportLibraries_jll", v"1.1.2";
               compat="1.1.1",
               platforms=filter(!Sys.isapple, platforms)),
    Dependency("LLVMOpenMP_jll"; compat="23.1.1", platforms=filter(Sys.isapple, platforms)),
]

# std::bit_cast needs GCC 11
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.11", preferred_gcc_version=v"11")

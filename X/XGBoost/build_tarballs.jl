using BinaryBuilder, Pkg

name = "XGBoost"
version = v"1.7.1"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to build XGBoost
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","534c940a7ea50ab3b8a827546ac9908f859379f2"), 
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

# Patch dmlc-core to use case-sensitive windows.h includes: https://github.com/dmlc/dmlc-core/pull/673
(cd dmlc-core; atomic_patch -p1 "../../patches/dmlc_windows.patch")

mkdir build && cd build
if [[ ${target} == x86_64-linux-gnu* ]]; then
    export CUDA_HOME=${WORKSPACE}/destdir/cuda
    export PATH=$PATH:$CUDA_HOME/bin
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DUSE_CUDA=ON -DBUILD_WITH_CUDA_CUB=ON
    make -j${nproc}
else
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" 
    make -j${nproc}
fi

# Manual installation, to avoid installing dmlc
cd ..
for header in include/xgboost/*.h; do
    install -Dv "${header}" "${includedir}/xgboost/$(basename ${header})"
done
install -Dvm 0755 xgboost${exeext} ${bindir}/xgboost${exeext}

if [[ ${target} == *mingw* ]]; then
    install -Dvm 0755 lib/xgboost.dll ${libdir}/xgboost.dll
else
    install -Dvm 0755 lib/libxgboost.${dlext} ${libdir}/libxgboost.${dlext}
fi

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
    ExecutableProduct("xgboost", :xgboost)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"11.0.3"); platforms = platforms[3:4]),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")

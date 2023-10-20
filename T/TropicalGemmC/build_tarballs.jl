using BinaryBuilder
using BinaryBuilderBase
using Pkg
using Base.BinaryPlatforms: arch, os

name = "TropicalGemmC"
version = v"0.1.1"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ArrogantGao/TropicalGemm_Cuda.git", "5510f1394e8b5dc4fc98df7ea640a54a417188a2")
]

script = raw"""
cd $WORKSPACE/srcdir
cd TropicalGemm_Cuda/

export CUDA_HOME=${WORKSPACE}/destdir/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

mkdir build
cd build

mv ${WORKSPACE}/destdir/cuda/lib ${WORKSPACE}/destdir/cuda/lib64

cmake .. -DCMAKE_CUDA_ARCHITECTURES=60 -DCMAKE_BUILD_TYPE=Release
make -j${nproc}

cd ..
for file in lib/*.${dlext}; do
    if [ -f "$file" ]; then
        install -Dvm 0755 $file ${libdir}/$(basename $file)
    fi
done

install_license /usr/share/licenses/MIT
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["lib_PlusMul_FP32"], :lib_PlusMul_FP32),
    LibraryProduct(["lib_PlusMul_FP64"], :lib_PlusMul_FP64),
    LibraryProduct(["lib_PlusMul_INT32"], :lib_PlusMul_INT32),
    LibraryProduct(["lib_PlusMul_INT64"], :lib_PlusMul_INT64),
    LibraryProduct(["lib_TropicalMaxMul_FP32"], :lib_TropicalMaxMul_FP32),
    LibraryProduct(["lib_TropicalMaxMul_FP64"], :lib_TropicalMaxMul_FP64),
    LibraryProduct(["lib_TropicalMaxMul_INT32"], :lib_TropicalMaxMul_INT32),
    LibraryProduct(["lib_TropicalMaxMul_INT64"], :lib_TropicalMaxMul_INT64),
    LibraryProduct(["lib_TropicalAndOr_Bool"], :lib_TropicalAndOr_Bool),
    LibraryProduct(["lib_TropicalMaxPlus_FP32"], :lib_TropicalMaxPlus_FP32),
    LibraryProduct(["lib_TropicalMaxPlus_FP64"], :lib_TropicalMaxPlus_FP64),
    LibraryProduct(["lib_TropicalMinPlus_FP32"], :lib_TropicalMinPlus_FP32),
    LibraryProduct(["lib_TropicalMinPlus_FP64"], :lib_TropicalMinPlus_FP64),
]

platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    dependencies = AbstractDependency[
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
        cuda_deps...
    ]

    build_tarballs(ARGS, name, version, sources,  script, [platform], products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat="1.6",
    augment_platform_block=CUDA.augment)
end

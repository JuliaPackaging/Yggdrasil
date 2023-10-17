using BinaryBuilder
using BinaryBuilderBase
using Pkg

name = "TropicalGemmC"
version = v"0.1.0"

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

mkdir build
cd build

cmake ..
make -j${nproc}

cd ..
for file in lib/*.${dlext}; do
    if [ -f "$file" ]; then
        install -Dvm 0755 $file ${libdir}/$(basename $file)
    fi
done

install_license /usr/share/licenses/MIT
"""

augment_platform_block = CUDA.augment

versions_to_build = [
    v"12.0",
    v"12.1"
]

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
    LibraryProduct(["lib_TropicalAndOr_Bool"], :TropicalAndOr_Bool),
    LibraryProduct(["lib_TropicalMaxPlus_FP32"], :TropicalMaxPlus_FP32),
    LibraryProduct(["lib_TropicalMaxPlus_FP64"], :TropicalMaxPlus_FP64),
    LibraryProduct(["lib_TropicalMinPlus_FP32"], :TropicalMinPlus_FP32),
    LibraryProduct(["lib_TropicalMinPlus_FP64"], :TropicalMinPlus_FP64),
]

platforms = [
    Platform("x86_64", "linux"),
]

for cuda_version in versions_to_build, platform in platforms

    cuda_platform = (os(platform) == "linux") && (arch(platform) in ["x86_64"])
    if !isnothing(cuda_version) && !cuda_platform
        continue
    end
    
    if cuda_platform
        augmented_platform = Platform(arch(platform), os(platform);
            cxxstring_abi = cxxstring_abi(platform),
            cuda=isnothing(cuda_version) ? "none" : CUDA.platform(cuda_version)
        )
    else
        augmented_platform = deepcopy(platform)
    end
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = AbstractDependency[
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, [augmented_platform])),
    ]

    if !isnothing(cuda_version)
        push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))))
        push!(dependencies, RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")))
    end

    build_tarballs(ARGS, name, version, sources,  script, [augmented_platform], products, dependencies;
                    preferred_gcc_version=v"8",
                    julia_compat="1.6",
                    augment_platform_block)
end

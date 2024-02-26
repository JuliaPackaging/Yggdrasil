using BinaryBuilder
using BinaryBuilderBase
using Pkg

name = "XGBoost"
version = v"2.0.1"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to build XGBoost
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","a408254c2f0c4a39a04430f9894579038414cb31"),
    DirectorySource("./bundled"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
    "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

# Patch dmlc-core to use case-sensitive windows.h includes: 
# https://github.com/dmlc/dmlc-core/pull/673
(cd dmlc-core; atomic_patch -p1 "../../patches/dmlc_windows.patch")

# https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/193
# error: 'any_cast<std::shared_ptr<xgboost::data::CSRArrayAdapter>>' 
# is unavailable: introduced in macOS 10.14
# `std::filesystem` support was introduced in macOS 10.15
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

mkdir build && cd build

if  [[ $bb_full_target == *-linux*cuda+1* ]]; then
    # nvcc writes to /tmp, which is a small tmpfs in our sandbox.
    # make it use the workspace instead
    export TMPDIR=${WORKSPACE}/tmpdir
    mkdir ${TMPDIR}

    export CUDA_HOME=${WORKSPACE}/destdir/cuda
    export PATH=$PATH:$CUDA_HOME/bin
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
            -DCUDA_TOOLKIT_ROOT_DIR=${WORKSPACE}/destdir/cuda \
            -DUSE_CUDA=ON \
            -DBUILD_WITH_CUDA_CUB=ON
    make -j${nproc}
else
    cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" 
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

augment_platform_block = CUDA.augment

versions_to_build = [
    nothing,
    v"11.4",
    v"12.0",
]

cuda_preambles = Dict(
    nothing => "",
    v"11.4" => "CUDA_ARCHS=\"60;70;75;80\";",
    v"12.0" => "CUDA_ARCHS=\"60;70;75;80;89;90\";",
)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
    ExecutableProduct("xgboost", :xgboost)
]

platforms = expand_cxxstring_abis(supported_platforms())

for cuda_version in versions_to_build, platform in platforms

    cuda_platform = (os(platform) == "linux") && (arch(platform) in ["x86_64"])
    if !isnothing(cuda_version) && !cuda_platform
        continue
    end
    
    # For platforms we can't create cuda builds on, we want to avoid adding cuda=none
    # https://github.com/JuliaPackaging/Yggdrasil/issues/6911#issuecomment-1599350319
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
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); 
            platforms=filter(!Sys.isbsd, [augmented_platform])),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); 
            platforms=filter(Sys.isbsd, [augmented_platform])),
    ]

    if !isnothing(cuda_version)
        push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))))
        push!(dependencies, RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")))
    end
    preamble = cuda_preambles[cuda_version]

    build_tarballs(ARGS, name, version, sources,  preamble*script, [augmented_platform], products, dependencies;
                    preferred_gcc_version=v"9",
                    julia_compat="1.6",
                    augment_platform_block)
end

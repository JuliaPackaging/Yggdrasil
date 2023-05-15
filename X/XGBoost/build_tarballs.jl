using BinaryBuilder, Pkg, BinaryBuilderBase

name = "XGBoost"
version = v"1.7.5"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to build XGBoost
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","21d95f3d8f23873a76f8afaad0fee5fa3e00eafe"), 
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

# Patch dmlc-core to use case-sensitive windows.h includes: https://github.com/dmlc/dmlc-core/pull/673
(cd dmlc-core; atomic_patch -p1 "../../patches/dmlc_windows.patch")

mkdir build && cd build
if  [[ $bb_full_target == x86_64-linux*cuda* ]]; then
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

versions_to_build = [
    nothing,
    v"11.0",
    v"12.0", 
]

# XXX: support only specifying major/minor version (JuliaPackaging/BinaryBuilder.jl#/1212)
cuda_full_versions = Dict(
    v"11.0" => v"11.0.3",
    v"12.0" => v"12.0.1",
)

cuda_archs = Dict(
    v"11.0" => "60;70;75;80",
    v"12.0" => "60;70;75;80;89;90",
)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
    ExecutableProduct("xgboost", :xgboost)
]

for cuda_version in versions_to_build

    if isnothing(cuda_version)
        platforms = expand_cxxstring_abis(supported_platforms())
        dependencies = [
            # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
            # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
            Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
            Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
        ]
        preamble = ""
    else
        platforms = expand_cxxstring_abis(Platform("x86_64", "linux"; 
                            cuda=CUDA.platform(cuda_version)))
        dependencies = [
            Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
            BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_full_versions[cuda_version]), platforms=platforms),
            RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"), platforms=platforms),
        ]
        preamble = """
        CUDA_ARCHS="$(cuda_archs[cuda_version])"
        """
        preamble = ""
    end

    # Build the tarballs, and possibly a `build.jl` as well.
    build_tarballs(ARGS, name, version, sources,  preamble*script, platforms, products, dependencies; 
                    preferred_gcc_version=v"8", 
                    julia_compat="1.6",
                    augment_platform_block=CUDA.augment)

end

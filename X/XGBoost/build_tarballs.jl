using BinaryBuilder, Pkg

name = "XGBoost"
version = v"1.7.5"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

sources = [
    GitSource("https://github.com/dmlc/xgboost.git","21d95f3d8f23873a76f8afaad0fee5fa3e00eafe"), 
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v11.0.3%2B4/CUDA_full.v11.0.3.x86_64-linux-gnu.tar.gz", 
        "d4772bc20aef89fb61989c294d819ca446ae7431ac732f3454f5e866e3633dc2"; 
        unpack_target = "CUDA_full.v11.0"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUDA_full_jll.jl/releases/download/CUDA_full-v12.0.1%2B2/CUDA_full.v12.0.1.x86_64-linux-gnu.tar.gz", 
        "99146b1c6c2fe18977df8618770545692435e7b6fd12ac19f50f9980774d4fc5"; 
        unpack_target = "CUDA_full.v12.0"),
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

    cuda_version=`echo $bb_full_target | sed -E -e 's/.*cuda\+([0-9]+\.[0-9]+).*/\1/'`
    cuda_version_major=`echo $cuda_version | cut -d . -f 1`
    cuda_version_minor=`echo $cuda_version | cut -d . -f 2`
    cuda_full_path="$WORKSPACE/srcdir/CUDA_full.v$cuda_version/cuda"
    export PATH=$PATH:$cuda_full_path/bin
    export CUDACXX=$cuda_full_path/bin/nvcc
    export CUDA_HOME=$cuda_full_path

    # Set cuda_archs based on the CUDA version
    if [[ $cuda_version_major == "11" ]]
    then
        export cuda_archs="60;70;75;80"
    elif [[ $cuda_version_major == "12" ]]
    then
        export cuda_archs="60;70;75;80;89;90"
    fi

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

platforms = expand_cxxstring_abis(supported_platforms())

cuda_versions_to_build = [v"11.0", v"12.0"]

cuda_platforms = Platform[]
for cuda_version in cuda_versions_to_build
    append!(cuda_platforms, expand_cxxstring_abis(Platform("x86_64", "linux"; 
                            cuda=CUDA.platform(cuda_version))))
end

append!(platforms, cuda_platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
    ExecutableProduct("xgboost", :xgboost)
]

dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"), platforms=cuda_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
                preferred_gcc_version=v"8", 
                julia_compat="1.6",
                augment_platform_block=CUDA.augment)

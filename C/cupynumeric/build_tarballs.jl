using BinaryBuilder
import Pkg: PackageSpec
using Base.BinaryPlatforms: arch, os, tags

# needed for libjulia_platforms and julia_versions
const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cupynumeric"
version = v"25.5" # cupynumeric has 05, but Julia doesn't like that
sources = [
    GitSource("https://github.com/nv-legate/cupynumeric.git","cbd9a098b32531d68f1b3007ef86bb8d3859174d"),
    GitSource("https://github.com/MatthewsResearchGroup/tblis.git", "c4f81e08b2827e72335baa7bf91a245f72c43970"),
    ArchiveSource("https://github.com/JuliaBinaryWrappers/CUTENSOR_jll.jl/releases/download/CUTENSOR-v2.2.0%2B0/CUTENSOR.v2.2.0.x86_64-linux-gnu-cuda+12.0.tar.gz",
                     "1c243b48e189070fefcdd603f87c06fada2d71c911dea7028748ad7a4315b816")
]


# These should match the legate_jll build_tarballs script
MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"12.8.999"

script = raw"""

    # Build crashes without this
    export TMPDIR=${WORKSPACE}/tmpdir
    mkdir -p ${TMPDIR}

    # Copy cuTensor archive to proper dirs
    cd ${WORKSPACE}/srcdir
    cp -a ./include/. ${includedir}
    cp -a ./lib/. ${libdir}

    # Put new CMake first on path
    export PATH=${host_bindir}:$PATH

    # Necessary operations to cross compile CUDA from x86_64 to aarch64
    if [[ "${target}" == aarch64-linux-* ]]; then

        # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
        export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
        
        # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
        NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
        rm -rf ${prefix}/cuda/bin
        cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin
        
        rm -rf ${prefix}/cuda/nvvm/bin
        cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin

        export NVCC_PREPEND_FLAGS="-ccbin='${CXX}'"
    fi

    export CUDA_HOME=${prefix}/cuda;
    export PATH=$PATH:$CUDA_HOME/bin
    export CUDACXX=$CUDA_HOME/bin/nvcc

    ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

    ## BUILD TBLIS ##
    cd ${WORKSPACE}/srcdir/tblis

    for i in ./Makefile.* ./configure*; do

        # Building in container forbids -march options
        sed -i "s/-march[^ ]*//g" $i

    done

    case ${target} in
        *"x86_64"*"linux"*"gnu"*) 
            export BLI_CONFIG=x86,reference
            ;;
        *"aarch64"*)
            ;;
        *)
            ;;
    esac

    ./configure \
        --prefix=$prefix \
        --build=${MACHTYPE} \
        --host=${target} \
        --with-label-type=int32_t \
        --with-length-type=int64_t \
        --with-stride-type=int64_t \
        --enable-thread-model=openmp \
        --enable-config=${BLI_CONFIG}

    make -j ${nproc} && make install

    cd ${WORKSPACE}/srcdir/cupynumeric

    mkdir build
    cmake -S . -B build \
        -Dlegate_ROOT:STRING=${prefix} \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DNCCL_LIBRARY=${libdir}/libnccl.so \
        -DNCCL_INCLUDE_DIR=${includedir} \
        -Dcutensor_LIBRARY=${libdir}/libcutensor.so \
        -Dcutensor_INCLUDE_DIR=${includedir} \
        -DBLAS_LIBRARIES=${libdir}/libopenblas.so \

    cmake --build build --parallel ${nproc} --verbose
    cmake --install build

    install_license $WORKSPACE/srcdir/cupynumeric*/LICENSE
    install_license $WORKSPACE/srcdir/share/licenses/CUTENSOR/LICENSE


"""

platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

# for now NO ARM support, tblis doesnt have docs on how to build for arm
filter!(p -> arch(p) == "x86_64", platforms)

platforms = expand_cxxstring_abis(platforms) 
filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

products = [
    LibraryProduct("libcupynumeric", :libcupynumeric)
] 

dependencies = [
    Dependency("legate_jll"; compat = "=25.5"), # Legate versioning is Year.Month
    # Dependency("CUTENSOR_jll", compat = "2.2"), # supplied via ArchiveSource
    Dependency("OpenBLAS32_jll"),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")) 
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    cuda_ver = platform["cuda"]

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    if arch(platform) == "aarch64"
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
    end

    build_tarballs(
        ARGS, name, version, platform_sources, 
        script, [platform], products, [dependencies; cuda_deps];
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true, dont_dlopen = true,
        augment_platform_block = CUDA.augment
    )


end



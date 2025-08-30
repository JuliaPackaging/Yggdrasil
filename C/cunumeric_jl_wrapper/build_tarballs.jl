using BinaryBuilder, Pkg

# needed for libjulia_platforms and julia_versions
const YGGDRASIL_DIR = "../../"
include(joinpath(YGGDRASIL_DIR, "L", "libjulia", "common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cunumeric_jl_wrapper"
version = v"25.5.1" # cupynumeric has 05, but Julia doesn't like that
sources = [
    GitSource("https://github.com/JuliaLegate/cunumeric_jl_wrapper.git","37c076f8f08afb61a83ca68cf3529a96f9bacb55"),
]

MIN_JULIA_VERSION = v"1.10"
MAX_JULIA_VERSION = v"1.11.999"

# These should match the cupynumeric_jll build_tarballs script
MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"12.8.999"

script = raw"""
    # Put new CMake first on path & delete old one
    apk del cmake
    export PATH=${host_bindir}:$PATH
    
    cd ${WORKSPACE}/srcdir/
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
    export CUDA_LIB=${CUDA_HOME}/lib
    #ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64
    
    mkdir build
    cd build
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_FIND_ROOT_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DJulia_PREFIX=${prefix} \
        ../cunumeric_jl_wrapper/
    VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
    install_license $WORKSPACE/srcdir/cunumeric_jl_wrapper*/LICENSE
"""

julia_versions = filter!(v -> v >= MIN_JULIA_VERSION && v <= MAX_JULIA_VERSION , julia_versions)
cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

platforms = AbstractPlatform[]

# Create all combos of CUDA + Julia Versions...so many builds :( 
for p in cuda_platforms
    for v in julia_versions
        new_p = deepcopy(p)
        new_p["julia_version"] = string(v)
        push!(platforms, new_p)
    end
end

filter!(p -> arch(p) == "x86_64", platforms)
platforms = expand_cxxstring_abis(platforms) 
filter!(p -> cxxstring_abi(p) == "cxx11", platforms)

products = [
    LibraryProduct("libcunumeric_jl_wrapper", :libcunumeric_jl_wrapper),
    LibraryProduct("libcunumeric_c_wrapper", :libcunumeric_c_wrapper),
] 


dependencies = [
    Dependency("cupynumeric_jll"; compat = "=25.5"), # versioning is Year.Month
    Dependency("legate_jll"; compat = "=25.5"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.3"),
    BuildDependency("libjulia_jll"),
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.30.2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")) 
]

for platform in platforms

    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    cuda_ver = platform["cuda"]

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    # Add x86_64 CUDA_SDK, nvcc isn't actually used but CMake
    # FindCUDAToolkit will get mad if its not present
    if arch(platform) == "aarch64"
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
    end

    build_tarballs(
        ARGS, name, version, platform_sources, 
        script, [platform], products, [dependencies; cuda_deps];
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true,
        augment_platform_block = CUDA.augment,
    )


end


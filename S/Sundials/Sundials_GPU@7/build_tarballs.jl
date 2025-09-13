using BinaryBuilder
using BinaryBuilderBase
using Pkg

name = "Sundials_GPU"
version = v"7.4.0"
ygg_version = v"7.4.1" # Fake version since we are changing deps

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

# Collection of sources required to build Sundials
sources = [
    GitSource("https://github.com/LLNL/sundials.git",
              "8e17876d3b4d682b4098684b07a85b005a122f81"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

apk del cmake

# Set up CFLAGS
cd $WORKSPACE/srcdir/sundials*/cmake/tpl
if [[ "${target}" == *-mingw* ]]; then
    # Work around https://github.com/LLNL/sundials/issues/29
    # When looking for KLU libraries, CMake searches only for import libraries,
    # this patch ensures we look also for shared libraries.
    atomic_patch -p3 $WORKSPACE/srcdir/patches/Sundials_findklu_suffixes.patch
fi

# Build
cd $WORKSPACE/srcdir/sundials*
mkdir build && cd build

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DEXAMPLES_ENABLE_C=OFF -DENABLE_KLU=ON -DKLU_INCLUDE_DIR="${includedir}/suitesparse" -DKLU_LIBRARY_DIR="${libdir}" -DKLU_WORKS=ON -DENABLE_LAPACK=ON -DLAPACK_WORKS=ON -DBLA_VENDOR="OpenBLAS")

if  [[ $bb_full_target == *-linux*cuda+1* ]]; then
    # nvcc writes to /tmp, which is a small tmpfs in our sandbox.
    # make it use the workspace instead
    export TMPDIR=${WORKSPACE}/tmpdir
    mkdir ${TMPDIR}

    export CUDA_HOME=${WORKSPACE}/destdir/cuda
    export PATH=$PATH:$CUDA_HOME/bin

    cmake "${CMAKE_FLAGS}" -DENABLE_CUDA=ON ..
else
    cmake "${CMAKE_FLAGS}" ..
fi

cmake --build . --parallel ${nproc}
cmake --install .
rm -f ${libdir}/*.a
"""

# We attempt to build for all the platforms OpenBLAS32_jll is available for
platforms = expand_gfortran_versions(supported_platforms())
filter!(p -> !(arch(p) == "powerpc64le" && libgfortran_version(p) < v"5"), platforms)

products = [
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_nvecmanyvector", :libsundials_nvecmanyvector),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunlinsollapackband", :libsundials_sunlinsollapackband),
    LibraryProduct("libsundials_sunlinsollapackdense", :libsundials_sunlinsollapackdense),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct("libsundials_sunnonlinsolfixedpoint", :libsundials_sunnonlinsolfixedpoint),
    LibraryProduct("libsundials_sunnonlinsolnewton", :libsundials_sunnonlinsolnewton),
    # Note: libsundials_generic was renamed to libsundials_core in v7
    LibraryProduct("libsundials_core", :libsundials_core),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("SuiteSparse32_jll"),
]

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

    append!(dependencies,
            AbstractDependency[
                # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
                # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
                Dependency("CompilerSupportLibraries_jll";
                           platforms=filter(!Sys.isbsd, [augmented_platform])),
                Dependency("LLVMOpenMP_jll";
                           platforms=filter(Sys.isbsd, [augmented_platform])),
            ]
            )

    if !isnothing(cuda_version)
        push!(dependencies, BuildDependency("CUDA_full_jll", version=CUDA.full_version(cuda_version)))
        push!(dependencies, RuntimeDependency("CUDA_Runtime_jll"))
    end
    preamble = cuda_preambles[cuda_version]

    build_tarballs(ARGS, name, version, sources,
                   preamble*script, [augmented_platform], products, dependencies;
                   preferred_gcc_version=v"6",
                   julia_compat="1.6",
                   augment_platform_block)
end

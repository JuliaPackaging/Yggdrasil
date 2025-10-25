using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.9.2"

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "719d893822f736af58589dfb46444c56f83519cb")
]
platforms = expand_cxxstring_abis([Platform("x86_64", "linux"; libc="glibc")])
platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    platform => [
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/compiler_shared-2025.2.0-intel_766.conda",
            "5adbaa605f2fb1d1abc01b3bb92b15dd3b0a2d17d83e10632267b7c2db81f96d",
            filename="compiler_shared",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2025.2.0-intel_766.conda",
            "72b0cd92ef6822a6d135cb5918fbd22351f78ef67ded2bbf48e939cc96f09b28",
            filename="dpcpp-cpp-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2025.2.0-intel_766.conda",
            "799c13a0c1da92c8748068746c7433bb3540bce75d58b8cb80a396895a74e683",
            filename="dpcpp_impl_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2025.2.0-intel_766.conda",
            "85ac32ce4cc04e43a823fab651f58d50b88cdac055e54e2ac2979d86ce2ac7bc",
            filename="dpcpp_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2025.2.0-intel_766.conda",
            "d93bb638b85773694d8f8d462a3cc81805b01cb1c25b85359874c6d57f555504",
            filename="intel-cmplr-lib-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2025.2.0-intel_766.conda",
            "de1e0f84c2d5e3f9cf3fbb72d6e309c5504ef85633342ebc26c39f01320aa80a",
            filename="intel-cmplr-lib-ur",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2025.2.0-intel_766.conda",
            "09a5b746348997b89573ba5d1fdaa5334d9e097eefb3ad7079d30e54342e6f6b",
            filename="intel-cmplr-lic-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2025.2.0-intel_766.conda",
            "ecdcefe9abb6937a0f070b6398f31aa99b11fed0a4d6910c182e62b97bc11218",
            filename="intel-opencl-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2025.2.0-intel_766.conda",
            "192b1cb550a82d3d81761db2310e24c3b8bb7f7f9c28ad22b1f63ee98f366b92",
            filename="intel-openmp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2025.2.0-intel_766.conda",
            "5183872e85c1ad972ca38d459bc9e294109aca478b9fbc048195e40a5a3d6f0b",
            filename="intel-sycl-rt",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2025.2.0-intel_628.conda",
            "3d6ac337434cb3d6f2e50229d5ab948eb83ea4a7364c2ce7e4fa40a4bbca3f90",
            filename="mkl",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2025.2.0-intel_628.conda",
            "41cd0618c0faf8934d6c9661e559ded53048cdf39b430eb152e6c2c156949f41",
            filename="mkl-devel",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2025.2.0-intel_628.conda",
            "b60be992607a7c8f4977ad51539f3528a474d555bbc424412d30df5ef2887d59",
            filename="mkl-devel-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2025.2.0-intel_628.conda",
            "226c7ce815412a1facef0cf7744ba1997125927a4021b3525775619951e3934f",
            filename="mkl-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2025.2.0-intel_628.conda",
            "b8485a410756687dae93c2b83f58a01bf38e94c32279d845f72e8c0d60de83ab",
            filename="mkl-include",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2025.2.0-intel_628.conda",
            "f9cbb4403dfe2131bafefae974b43824512ef80a069a54dcebf82afe85d07afb",
            filename="onemkl-sycl-blas",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2025.2.0-intel_628.conda",
            "585495feb1cad8fe32203b253fb04c308a810fb7453bc9fe6533dfb3d7704c60",
            filename="onemkl-sycl-datafitting",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2025.2.0-intel_628.conda",
            "5a38332caca76926c413228682fc8d05c0f5bb90198f6c7173911de39b04d918",
            filename="onemkl-sycl-dft",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2025.2.0-intel_628.conda",
            "41ee24eeefe481a3f4e029cbd023e606d058f30d8eca97bc6eb9ab978558de03",
            filename="onemkl-sycl-lapack",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2025.2.0-intel_628.conda",
            "b3a9007dff182c3e6652836f0d9161047c5cb1e756863b6389221b1ecf41c12a",
            filename="onemkl-sycl-rng",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2025.2.0-intel_628.conda",
            "c53cc29da116f10b68494929d46acf6a407488f4fceaab99ddfbadbde086da90",
            filename="onemkl-sycl-sparse",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2025.2.0-intel_628.conda",
            "2ebb028163df45e7954514d96c366495c5202694f6bd4ae0fdc395e740dae8bc",
            filename="onemkl-sycl-stats",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2025.2.0-intel_628.conda",
            "12ba270cb2d16d5c3c9045f7234fbd779294a92123299d03898ac28e6ef6ff69",
            filename="onemkl-sycl-vm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-2022.2.0-intel_507.conda",
            "b806f156ed362a16473d1e0a93c768c4ecca2f2a6397f525c4905d34593cc68a",
            filename="tbb",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-devel-2022.2.0-intel_507.conda",
            "9dbb31455b1759fb9031e6828fd05cdd4e1893934b2e437112a16581038775ba",
            filename="tbb-devel",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tcm-1.4.0-intel_345.conda",
            "27583e316ca872175860f4e2063770de95841cb5c5af49aee46a1c64f537dd1c",
            filename="tcm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/umf-0.11.0-intel_394.conda",
            "6db8267c1cf39012e8e09a6359fe4641217910fc22483cf07df4b9aea49aa863",
            filename="umf",
        ),
    ]
    for platform in platforms
)

script = raw"""
for package in compiler_shared dpcpp-cpp-rt dpcpp_impl_linux-64 dpcpp_linux-64 intel-cmplr-lib-rt \
               intel-cmplr-lib-ur intel-cmplr-lic-rt intel-opencl-rt intel-openmp intel-sycl-rt mkl \
               mkl-devel mkl-devel-dpcpp mkl-dpcpp mkl-include onemkl-sycl-blas onemkl-sycl-datafitting \
               onemkl-sycl-dft onemkl-sycl-lapack onemkl-sycl-rng onemkl-sycl-sparse onemkl-sycl-stats \
               onemkl-sycl-vm tbb tbb-devel tcm umf; do
    unzip -o ${package} -d "${WORKSPACE}/srcdir"
done

# Install zstd
apk add zstd

find "${WORKSPACE}/srcdir" -name '*.tar.zst' | while read -r archive; do
    echo "Extracting $archive..."
    tar --use-compress-program=unzstd -xf "$archive" -C "${WORKSPACE}/srcdir"
done

# install dependencies in the prefix
# NOTE: these dependencies _should_ be packaged as JLLs we can depend on,
#       but that's just a lot of work and not worth it for this single build.
mkdir -p ${libdir} ${includedir}
cp -r include/* ${includedir}
for lib in sycl svml irng imf intlc ur_loader ur_adapter \
           mkl_cdft_core mkl_core mkl_intel_ilp64 mkl_sequential mkl_sycl \
           mkl_avx mkl_def umf tcm; do
    install -Dvm 755 lib/lib${lib}*.so* -t ${libdir}
done

install_license "info/licenses/license.txt"

cd oneAPI.jl/deps

CMAKE_FLAGS=()
# Tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=RelWithDebInfo)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Search for libraries in the prefix
# XXX: why is this needed?
CMAKE_FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}")
# BUG: intel/llvm#5932
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-I${includedir}/sycl")
cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}

ninja -C build -j ${nproc} install

# remove build-time dependencies we don't need
rm -rf ${includedir}
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["liboneapi_support"], :liboneapi_support),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("oneAPI_Level_Zero_Headers_jll"),
    BuildDependency("oneAPI_Support_Headers_jll"),
    Dependency("oneAPI_Level_Zero_Loader_jll"),
    Dependency("OpenCL_jll"),
    Dependency("Hwloc_jll"),
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)
include("../../fancy_toys.jl")
filter!(platform_sources) do (platform, sources)
    should_build_platform(triplet(platform))
end

for (idx, (platform, sources)) in enumerate(platform_sources)
    # Use "--register" only on the last invocation of build_tarballs
    if idx < length(platform_sources)
        args = non_reg_ARGS
    else
        args = ARGS
    end
    build_tarballs(args, name, version, [generic_sources; sources], script, [platform],
                   products, dependencies; preferred_gcc_version=v"8")
end

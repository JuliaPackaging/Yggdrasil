using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.6.1"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "12e0d98cdec7d564fecb032bc2b6ceab30bc42c3")
]

platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2024.2.1-intel_1079.tar.bz2",
            "58b58402b438c25f4270e303b417ccae02b46e2f0bb4e363c014897fb79e0aab"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2024.2.1-intel_1079.tar.bz2",
            "eae3ff6d83299a73f1c2f6b390fcfc9c2150881ec90e5358be07ecd2ae3e0a40"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2024.2.1-intel_1079.tar.bz2",
            "5f68fdb0ee377980cdcda414469e2d782b97bae4abea9d8183007469523b4724"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/icc_rt-2024.2.1-intel_1079.tar.bz2",
            "3f5eb6990d6f804f6af0074f9ac6744a641005ababb22390e288c5b3f593748d"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2024.2.1-intel_1079.tar.bz2",
            "b4262c8f228426ead2c6566ef18ad53e9c83b5c6b6408c2af255fcd3d98cf10f"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2024.2.1-intel_1079.tar.bz2",
            "d0abdbc25b665594dfc585f948f1278eca965f30b89b474329ff0375f3c390b1"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2024.2.1-intel_1079.tar.bz2",
            "823fb3fe40fdef28e9a4ed8d7aea212ba82574b36eeb0377fa6cf8fc436c2184"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2024.2.1-intel_1079.tar.bz2",
            "1cfb2421d215144f0843cbd6e279cc0df96f31c0ea56605b701e4ba8f429ee34"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2024.2.1-intel_1079.tar.bz2",
            "e9fe4d67441ded9497033590d5662fcc833f694c20cdf1fd009a49cd480d02ec"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2024.2.1-intel_1079.tar.bz2",
            "84397fb0fb1aaa3bd3cdb1cd77312013c86d231b01b582feb047991d9d1abf84"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2024.2.1-intel_103.tar.bz2",
            "9b710342f4d2751c8fa0919814679baaa5976699fc101f5f5be41d57f9074612"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2024.2.1-intel_103.tar.bz2",
            "fcd4fecdc19712fc98290e28926a3243d8f1c3d1938c7b078adc5b64eb47c6d9"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2024.2.1-intel_103.tar.bz2",
            "abb784cc37c2bb9d05daa4271ad9ee917eecb9a907c8706230fed162f820d11e"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2024.2.1-intel_103.tar.bz2",
            "bce79062a4ac061eed8b55eb6d75c99ab1c8c67b985759f774eafcc40ba273a4"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2024.2.1-intel_103.tar.bz2",
            "df19cbc68fda9e125445df8ea94a7af2c6a8cb009193104741c9f2d1223de193"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2024.2.1-intel_103.tar.bz2",
            "01b4b91a601047bd92bb8d0e2da485e5dae3c62ceaa22f06a8a927c4c326ac5f"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2024.2.1-intel_103.tar.bz2",
            "bc93ece7cb0e03e1dabc779156e26a6f90709e4619e68ad4c5ffeb60684d0e20"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2024.2.1-intel_103.tar.bz2",
            "d024615315d94b7d351b78e1c25e3e76a5353359943b5cd7fe61931304b21fb5"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2024.2.1-intel_103.tar.bz2",
            "13b5bd1ca55b932b05478c22302cdf6908816718366bbe967fa1c360ee4c17a0"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2024.2.1-intel_103.tar.bz2",
            "edb46e5f663aadfb842b6e109570d522fccccec0cb2f0a0c938b0fbe87c17188"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2024.2.1-intel_103.tar.bz2",
            "bf477d83c2027396778d9320171f322dd74f6786a8de2ae078b9a4476e65d828"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2024.2.1-intel_103.tar.bz2",
            "56fde8447e0fe80098abd68cfccecdcaeaeb39cbee84df7aa035e6de7201b378"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2024.2.1-intel_103.tar.bz2",
            "56f87cd414570a9b06eccff6aef40c9ddaf8fab86f07628d917296fb0ad18000"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-2021.13.1-intel_12.tar.bz2",
            "eacc00ee2442cfaf9efb1cd8ee227f76d24fc5a4a14853e328c0b4780f83dd41"
        ),
    ]
)

script = raw"""
install_license "info/licenses/license.txt"

# install dependencies in the prefix
# NOTE: these dependencies _should_ be packaged as JLLs we can depend on,
#       but that's just a lot of work and not worth it for this single build.
mkdir -p ${libdir} ${includedir}
cp -r include/* ${includedir}
for lib in sycl svml irng imf intlc pi_level_zero pi_opencl \
           mkl_core mkl_intel_ilp64 mkl_sequential mkl_sycl \
           mkl_avx mkl_def; do
    cp -a lib/lib${lib}*.so* ${libdir}
done

cd oneAPI.jl/deps

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=RelWithDebInfo)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Search for libraries in the prefix
# XXX: why is this needed?
CMAKE_FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}")
# BUG: intel/llvm#5932
CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="-I${includedir}/sycl")
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
# XXX: we use the Clang version to work around an issue with the SYCL headers
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}

ninja -C build -j ${nproc} install

# remove build-time dependencies we don't need
rm -rf ${includedir}

# XXX: MKL loads libOpenCL.so dynamically, and not by SONAME,
#      which isn't covered by our OpenCL_jll dependency.
#      to work around that, provide the actual library.
#      this does result in two copies of libOpenCL.so loaded,
#      but that seems to work fine...
# XXX: have upstream fix this by dlopen'ing by SONAME first
cp -f $(realpath ${libdir}/libOpenCL.so) ${libdir}/libOpenCL.so
"""

# The products that we will ensure are always built
products = [
    LibraryProduct(["liboneapi_support"], :liboneapi_support),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("oneAPI_Level_Zero_Headers_jll"),
    Dependency("oneAPI_Level_Zero_Loader_jll"),
    Dependency("OpenCL_jll"),
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

using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "oneAPI_Support"
version = v"0.10.0"

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "6336e40f435374ed588fcfd8ac6c792a56bdce67")
]
platforms = expand_cxxstring_abis([Platform("x86_64", "linux"; libc="glibc")])
platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    platform => [
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/compiler_shared-2025.3.1-intel_760.conda",
            "0663e2efa13b68ad94ce11c62bea1f6cdbee17e629a616b30e113ea2c9d88cda",
            filename="compiler_shared",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2025.3.1-intel_760.conda",
            "3629a524acc849270652a8ad985b819804bff2c22841c62c6ca2d73e4c62eb9f",
            filename="dpcpp-cpp-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2025.3.1-intel_760.conda",
            "c08e7e7383bc81dfdb63fe1cf3bdbf6614f565684b8782a8ee34aedb774c713d",
            filename="dpcpp_impl_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2025.3.1-intel_760.conda",
            "fae95c611d3a2277dfd867690b475b92d2ff95b6fb005e96da194abe2a8642db",
            filename="dpcpp_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2025.3.1-intel_760.conda",
            "f4bd30eefe93d28b69e7aef32d297415ae69c12754fc23daf45fe3abedf66b31",
            filename="intel-cmplr-lib-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2025.3.1-intel_760.conda",
            "1ac71a2ae242fdb28592e38ac620ab12933cfd685b233435e8db30e77e144e3f",
            filename="intel-cmplr-lib-ur",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2025.3.1-intel_760.conda",
            "80590e319968c681dc7ad612a3c0161b99d160e90a1529765fc8b710f190c40b",
            filename="intel-cmplr-lic-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2025.3.1-intel_760.conda",
            "4c0db4dd8ac4bb3717930776ae140f5e6cc59ab7dbd92792be8aec4894da6e3a",
            filename="intel-opencl-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2025.3.1-intel_760.conda",
            "be640123438f6741baff1b1bb511e9ff9987f36d35eb09f4cdd0d1eeb075e9f9",
            filename="intel-openmp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2025.3.1-intel_760.conda",
            "925bf6455471aa9c978f4e7e5610f514a0c7d0b8fba1ee78eb0c8ceaa95bf71e",
            filename="intel-sycl-rt",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2025.3.1-intel_8.conda",
            "fd4fbba07cfa579aea6fde28a6468cf98f350ec9e5939a936ef77b78d54e6a4e",
            filename="mkl",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2025.3.1-intel_8.conda",
            "c49f1491dae70e0d9459f67d22aceb7fc6b99ef6e6e398d01032eca9a3d1af81",
            filename="mkl-devel",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2025.3.1-intel_8.conda",
            "e883304560e97f4b62e1a13d2e25e0a89b1cd49fa184940ecc86a2e7d55be144",
            filename="mkl-devel-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2025.3.1-intel_8.conda",
            "71ad40ea231c45897fa664c943037f734d6dd20b58357d43d5dabe4f71681628",
            filename="mkl-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2025.3.1-intel_8.conda",
            "a1775c87558504365dbdbd2e51d91644caa9fcbafca82022cf84889630399593",
            filename="mkl-include",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2025.3.1-intel_8.conda",
            "c70a24fd3a5c198b2465aa27933c61ccec215f5e26a87843a74b7fc744f0bbd3",
            filename="onemkl-sycl-blas",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2025.3.1-intel_8.conda",
            "bae85a3b444cc1871bf4af5b8104003c9342791e856533e2623e45acb640868a",
            filename="onemkl-sycl-datafitting",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2025.3.1-intel_8.conda",
            "6009dbe3c40542376f3ef1efe4cb1ce719eac059def5fc299f19ff8d25678dbf",
            filename="onemkl-sycl-dft",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2025.3.1-intel_8.conda",
            "b1d6ebab6a0a3c7e030b4080e035cb4249d8f443337e4075f1ed31ed8dfda5c5",
            filename="onemkl-sycl-lapack",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2025.3.1-intel_8.conda",
            "30a478c33c02a434acaafb987bfefb5c0c17d3a9a322f5d12bfa4641e0feda84",
            filename="onemkl-sycl-rng",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2025.3.1-intel_8.conda",
            "178b93773f362bd9753acb0a3185231a70f7339de26c26a765572a30396de7b3",
            filename="onemkl-sycl-sparse",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2025.3.1-intel_8.conda",
            "c05ed45449fc290ad0083220417860013d35ec9329e0afa08487e3b13ec45bde",
            filename="onemkl-sycl-stats",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2025.3.1-intel_8.conda",
            "78139bad5752606d22ab67848c8faacf89e106cd4f63f2dca00c92d0ff192783",
            filename="onemkl-sycl-vm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-2022.3.1-intel_400.conda",
            "cc487cad19b3f97ff2dce59816238ddcf83b937e88fdfe4c016233499e5f9718",
            filename="tbb",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-devel-2022.3.1-intel_400.conda",
            "9917f8f17c5531edfbb93c8b6bb7fbe3c9cef02fafbe73578c157e94b38d6f26",
            filename="tbb-devel",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tcm-1.5.0-intel_489.conda",
            "594d122995085e639ac1383b6e39786f3617bbf8ac447cbcd2914ed1f2214c74",
            filename="tcm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/umf-1.0.3-intel_17.conda",
            "a8e2f29edd95dce924269ab4234900cf688a59d1d8c3057bf31ba83bcc719ca7",
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

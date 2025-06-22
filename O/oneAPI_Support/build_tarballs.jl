using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.8.0"

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "1c4121c8f9fea661c5c7fc2aa8a64ae04bf03ce7")
]

platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/compiler_shared-2025.1.0-intel_973.conda",
            "67ccc86fe050c75998cfc6456fc299fa9d0884acbbc3d11511a48519fead1c1f",
            filename="compiler_shared",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2025.1.0-intel_973.conda",
            "4fc84e70d2249d97461883b529311c9e8261c9d53cffeaa2df4bc2a77aba52a0",
            filename="dpcpp-cpp-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2025.1.0-intel_973.conda",
            "316f4f0d5ff5747eae004913a1498ce946ff1e84d4927159136f3468d7d0cc53",
            filename="dpcpp_impl_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2025.1.0-intel_973.conda",
            "79205c134076987590129315aeab60d45968f1e62213ad2739dec19c87bcffad",
            filename="dpcpp_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2025.1.0-intel_973.conda",
            "8c82039d357bc636e4f8c57bd51360924f2d0f0f89a4ec175eb21e9d29c67358",
            filename="intel-cmplr-lib-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2025.1.0-intel_973.conda",
            "8c1520aeef86f4dc2a5fd27f50d2fd5e8667f98cb5381d4d3128e853d0341672",
            filename="intel-cmplr-lib-ur",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2025.1.0-intel_973.conda",
            "31ef4fcfdf8d473aca78332430981d845c73b0e0c85727256ba0ff5180387219",
            filename="intel-cmplr-lic-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2025.1.0-intel_973.conda",
            "29e1c459881dba7395d3e4ac3ad95ee59e5d0312821b5819778493391c2b90bd",
            filename="intel-opencl-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2025.1.0-intel_973.conda",
            "9e6d6861aa25cae8bfa16753eee4138af5334864d0dca0f66d2484b0aa19d06c",
            filename="intel-openmp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2025.1.0-intel_973.conda",
            "a9eddaa0bff1e7bc1158a2f51edc7d151c2e0e8aa1889fc8685abb960309c80f",
            filename="intel-sycl-rt",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2025.1.0-intel_801.conda",
            "4ed0dc14d2d8dbf3840dbe2a89c3c6c89c0ff3fb63cb766616973135a0fb705c",
            filename="mkl",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2025.1.0-intel_801.conda",
            "9a00a6436fbfc884473e9a930c06d8408fddcdf89e52fa58710ce7ae3223d321",
            filename="mkl-devel",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2025.1.0-intel_801.conda",
            "ae5bfa9fd52f195f2be124fb5910f83c42d788dc767b7aadbacdde6eb6a79143",
            filename="mkl-devel-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2025.1.0-intel_801.conda",
            "fdedb9a3808dc1e083cd5dbb394a71d915f8d1722879ba00dda1920026143cd5",
            filename="mkl-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2025.1.0-intel_801.conda",
            "ccf54c873bb7527dc1aab08e7ab731e89d399c09f4cd94db374807a7d78f7902",
            filename="mkl-include",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2025.1.0-intel_801.conda",
            "3986cf0c8e790aa5f0c1fda3f8dbfcebf9b8703813252b1cbb044b16f2e802e2",
            filename="onemkl-sycl-blas",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2025.1.0-intel_801.conda",
            "c44c9c01490597a1b873294f5a574cf3a48514a0a8c81c63d031ebdcf2d7f0db",
            filename="onemkl-sycl-datafitting",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2025.1.0-intel_801.conda",
            "163c768430f1466b788e2df9d73dcdd8b32752394aba7f9706e98298ea1bb4db",
            filename="onemkl-sycl-dft",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2025.1.0-intel_801.conda",
            "5a7f69963c0679e5d349d1621d3f860f8965500b17662997de128abefcdc5dee",
            filename="onemkl-sycl-lapack",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2025.1.0-intel_801.conda",
            "d66422098849e00068c59901a7f8de8f8a82b364d9f375ba9868bd1fd75bb4d6",
            filename="onemkl-sycl-rng",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2025.1.0-intel_801.conda",
            "f225f86d0a49c17c51ddffe6e61c7e2cb2500b7fb31636305e77ef5ff9c67b3e",
            filename="onemkl-sycl-sparse",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2025.1.0-intel_801.conda",
            "dda92986341ceedeb14b8bf20f4e21b34409aba88c7f2864ae2f222c29837817",
            filename="onemkl-sycl-stats",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2025.1.0-intel_801.conda",
            "28c1d83fc1c05ed5c8ccf564c6a90ac07adec774a4f41ea5d0284dda6eb6e5d2",
            filename="onemkl-sycl-vm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-2022.1.0-intel_425.conda",
            "dce62b5727869d59f18479a3d46145de00ec7df9a1506f4b97248fe536d0519b",
            filename="tbb",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-devel-2022.1.0-intel_425.conda",
            "4fc61c2be5baead915ef397042613c5585476f5a178ef1debde9b9ed26204e14",
            filename="tbb-devel",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tcm-1.3.0-intel_309.conda",
            "d2034b65e60944c5747e8417294c10dad989687a77674166ee65dad9abb7e0e8",
            filename="tcm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/umf-0.10.0-intel_355.conda",
            "3363c4c77b35d8919206f37f5d5c1676c8f868c6689555760b31ededc938f9a3",
            filename="umf",
        ),
    ]
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
           mkl_core mkl_intel_ilp64 mkl_sequential mkl_sycl \
           mkl_avx mkl_def umf tcm; do
    cp -a lib/lib${lib}*.so* ${libdir}
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

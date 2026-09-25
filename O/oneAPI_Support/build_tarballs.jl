using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "oneAPI_Support"
version = v"0.11.0"

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "5093529311e36f530c5990e4b0b3669452c45d8c")
]
platforms = expand_cxxstring_abis([Platform("x86_64", "linux"; libc="glibc")])
platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    platform => [
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/compiler_shared-2026.1.0-intel_235.conda",
            "7e8a0ced69174ccf64481fae89fcc32761be8865f13cbbfa1e7b3b3cdcece307",
            filename="compiler_shared",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2026.1.0-intel_235.conda",
            "66fe74fc4af763fd8c3d4a87bd8b1c4a115adf922efe6f6ed1254a8d9b6aa72b",
            filename="dpcpp-cpp-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2026.1.0-intel_235.conda",
            "6e7fccd4837ece044776813fc071841032e278769beb5c5b0f928c2e92dc9bc0",
            filename="dpcpp_impl_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2026.1.0-intel_235.conda",
            "81fb9bc4a464ec1e80ace28c18747a05cca2f53d3aaf5b33744288f77ee636d6",
            filename="dpcpp_linux-64",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2026.1.0-intel_235.conda",
            "a88c146e1764c621c21058891281e8e578c7971142a810fb956e796f71c4dc1f",
            filename="intel-cmplr-lib-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2026.1.0-intel_235.conda",
            "c2ba8da30430912617ef3a33f965ac309718555512ba6ee5ed176c49ca3a4a51",
            filename="intel-cmplr-lib-ur",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2026.1.0-intel_235.conda",
            "b174730821f9d769378900443a936b49369e09c9b26fdfa984a79024ae5bf157",
            filename="intel-cmplr-lic-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2026.1.0-intel_235.conda",
            "035d3f4af3c05113799b4f42e53b91acc86b8cb90edb287622e6b570e29f1bbc",
            filename="intel-opencl-rt",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2026.1.0-intel_235.conda",
            "835aa8a1379fecdc348b5ee8814de2f9efd2df5836a45956b99a40347a9c5c22",
            filename="intel-openmp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2026.1.0-intel_235.conda",
            "2f5cc1b5f299825dcb7e55b7122034f325f33870787ccd4ed8864ee1dd7ec859",
            filename="intel-sycl-rt",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2026.1.0-intel_236.conda",
            "7c42de217537b7c859dd82173b5cc36eefc17422d25dd70250f935e7489faf14",
            filename="mkl",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2026.1.0-intel_236.conda",
            "19f9c6490d9f211c35298eb553258dfebaa996a013479732e42668da43691492",
            filename="mkl-devel",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2026.1.0-intel_236.conda",
            "32d8e7276444671357ba0f69179cbeee24757bca2934d6af25c7956959fb64b0",
            filename="mkl-devel-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2026.1.0-intel_236.conda",
            "e4066ebdb0352a05c8596b9f047bd9d3ed416cc2ee5d179740b11b541bbad6df",
            filename="mkl-dpcpp",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2026.1.0-intel_236.conda",
            "6f5e9476564543871ed49ba64e4bd3843cfea894bdf7e040cdf24c6fa7d35ee7",
            filename="mkl-include",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-license-2026.1.0-intel_236.conda",
            "ef5f0792d1af3c2b6da0d951637060125e6bc063768a6c71746fc3d357b0d452",
            filename="onemkl-license",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2026.1.0-intel_236.conda",
            "63d92a1a338cdfd053244205f9d3a411529a856299012dbb2bc860198faa5a2a",
            filename="onemkl-sycl-blas",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2026.1.0-intel_236.conda",
            "a9f97c54f8bd2bc877d23f7181f3157994f9782121d65e36b64ba223c744a9b7",
            filename="onemkl-sycl-datafitting",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2026.1.0-intel_236.conda",
            "f7635f49123952c90bb2914d257e99eb42e270c17aa38ef2be4f051b50a927cb",
            filename="onemkl-sycl-dft",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-include-2026.1.0-intel_236.conda",
            "dd5a6708327e2918f334982770926362b0ec3287af761369f0dcd89c6262e202",
            filename="onemkl-sycl-include",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2026.1.0-intel_236.conda",
            "3cc047fadbf02f014b02be5eb0a473277f54ac1b7430c3515a7d9ffc1f6c0b4c",
            filename="onemkl-sycl-lapack",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2026.1.0-intel_236.conda",
            "3aaf130954b5889844d098de0eee72693590495606ba42d5fc4edf80dcb6370f",
            filename="onemkl-sycl-rng",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2026.1.0-intel_236.conda",
            "a06ee503ab7215e74f029b4aa8ac33cba49bc9c0d59ae4349c051860b3977260",
            filename="onemkl-sycl-sparse",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2026.1.0-intel_236.conda",
            "a4014b106f87c556dd9467bb58dc37e5153647ba5aec33a5aac2fe82b6140a6a",
            filename="onemkl-sycl-stats",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2026.1.0-intel_236.conda",
            "4c56a4f5f1a5979d545fe13f121fadc334b3d4ea295d4d7a8ce806f39c00d013",
            filename="onemkl-sycl-vm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-2023.1.0-intel_151.conda",
            "9df775ed413fe80423f37e6563b8af586ec1ec44097da1595095ec5e31cd5a16",
            filename="tbb",
        ),
        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-devel-2023.1.0-intel_151.conda",
            "56906e12a28f7a2a639a124f5070b805146a9edb9d02aa48cfeb7decc50db197",
            filename="tbb-devel",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/tcm-1.5.0-intel_489.conda",
            "594d122995085e639ac1383b6e39786f3617bbf8ac447cbcd2914ed1f2214c74",
            filename="tcm",
        ),

        FileSource(
            "https://software.repos.intel.com/python/conda/linux-64/umf-1.1.0-intel_340.conda",
            "3414521045ed05a60ea8d3046ae0eb474bf045eebc296ac86e28f58efdb5ed42",
            filename="umf",
        ),
    ]
    for platform in platforms
)

script = raw"""
for package in compiler_shared dpcpp-cpp-rt dpcpp_impl_linux-64 dpcpp_linux-64 intel-cmplr-lib-rt \
               intel-cmplr-lib-ur intel-cmplr-lic-rt intel-opencl-rt intel-openmp intel-sycl-rt mkl \
               mkl-devel mkl-devel-dpcpp mkl-dpcpp mkl-include onemkl-license onemkl-sycl-blas \
               onemkl-sycl-datafitting onemkl-sycl-dft onemkl-sycl-include onemkl-sycl-lapack \
               onemkl-sycl-rng onemkl-sycl-sparse onemkl-sycl-stats onemkl-sycl-vm tbb tbb-devel \
               tcm umf; do
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
    # the headers the wrappers in oneAPI.jl/deps were generated from; keep in sync with the toolkit above
    BuildDependency(PackageSpec(name="oneAPI_Support_Headers_jll", version=v"2026.1.0+0")),
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

using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.3.0"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl", "b5293f160655f750165323bbb2853b4fc3af7e33")
]

platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp-cpp-rt-2024.0.0-intel_49819.tar.bz2",
            "22b4d8754399bab5790d282066697b8cc3c2f1cbcc1f4b2d340727a6d7aa2c35";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_impl_linux-64-2024.0.0-intel_49819.tar.bz2",
            "3790e698d3e7b65bc3ae09d9dd8a30325271e2ed4faa745d472ed4db01d0258b";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_linux-64-2024.0.0-intel_49819.tar.bz2",
            "9ab6468f7522e7b2a84e6f2b79664aea4ae4a928518c30688d1d1db1870cdc90";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/icc_rt-2024.0.0-intel_49819.tar.bz2",
            "2aae241f522fa2b9af449d87faf2469cbe8c149134d8a7a809bfd7a2b4743052";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lib-rt-2024.0.0-intel_49819.tar.bz2",
            "c0e0118ef321e4f0f5a8eac7ef04872ce538122eb8db2cb875d63bbc25520fd7";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lic-rt-2024.0.0-intel_49819.tar.bz2",
            "4c9b9784ae53f47781d11d7a507fa0ce3de150769e049042f148e4e1c14fab7d";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-opencl-rt-2024.0.0-intel_49819.tar.bz2",
            "618506a21a5ad8ce19369c65496ea8fa3b00fef16f2e22fd335b1ebb5846bd57";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-openmp-2024.0.0-intel_49819.tar.bz2",
            "feee49a26abc74ef0b57cfb6f521b427d6a93e7d8293d30e941b70d5fd0ab2d9";
        ),


        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-2024.0.0-intel_49656.tar.bz2",
            "e02ad8cf2b0d1c18c4c0a6a06cb23ec6dc076678ab1e5bbc55876aa56f390458";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-2024.0.0-intel_49656.tar.bz2",
            "f6c37ade3153a0a98cf1f50346af32be1b87c4c3cb09e4f7b94dcb77b4896bd7";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-dpcpp-2024.0.0-intel_49656.tar.bz2",
            "ba52047546ced5a6b2060dd6c59384af1ab9aefaa47fdc202fbbde2d07602658";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-dpcpp-2024.0.0-intel_49656.tar.bz2",
            "90065d0dc77d5b61383418aba7f2162e89159d75da5ae2af01bccfcc406010c4";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-include-2024.0.0-intel_49656.tar.bz2",
            "fcbdf5d4197f18fb91fa1d9648f35a45628cc1131ff58c83dcbafe2767490571";
        ),

        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-blas-2024.0.0-intel_49656.tar.bz2",
            "fb8e20ed64ba32602173a70ef1006bec8efd3baad5e5acee79a4bdad3372ba53";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-lapack-2024.0.0-intel_49656.tar.bz2",
            "64908222e5b2d8f0859741bb0c1a9be57f452f284a271d9540fd8e44a814c0aa";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-sparse-2024.0.0-intel_49656.tar.bz2",
            "43398954718cfcc82798126716f3b8c6d300c54f2fbf7502eccfef218ed01165"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-datafitting-2024.0.0-intel_49656.tar.bz2",
            "1383e8f10540d1a6cb892841d44503e765041c730562b32be7b61cff570bab3e"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-dft-2024.0.0-intel_49656.tar.bz2",
            "2f881c965a9cecbdcc0a0361b7f1c5d07d580cc7a1fe8e9a7f461d6134006623"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-rng-2024.0.0-intel_49656.tar.bz2",
            "7bd159c258184a4c74dae84e666538d233b6bfedc1c6413a0c9cfcc42934c194"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-stats-2024.0.0-intel_49656.tar.bz2",
            "5ee1eb1fde278e5e98bc58c53137602c3c939a9a593cd7729c15440ee3196ece"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-vm-2024.0.0-intel_49656.tar.bz2",
            "2d65f55ddc91d334abfb8e119303046e22d5b7070ad522a3d8a8681b1bd9cf26"
        ),
    ]
)

script = raw"""
install_license "info/licenses/license.txt"

# install dependencies in the prefix
# NOTE: these dependencies _should_ be packaged as JLLs we can depend on,
#       but that's just a lot of work and not worth it for this single build.
mkdir -p ${libdir} ${includedir}
mv lib/clang/*/include/CL ${includedir}
rm -rf lib/clang
cp -r include/* ${includedir}
for lib in sycl OpenCL svml irng imf intlc pi_level_zero pi_opencl \
           mkl_core mkl_intel_ilp64 mkl_sequential mkl_sycl; do
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
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
# XXX: we use the Clang version to work around an issue with the SYCL headers
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake)
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
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
    Dependency("oneAPI_Level_Zero_Loader_jll")
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

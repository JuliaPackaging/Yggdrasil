using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.6.0"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "1a4e9fa4bf8283474cad062ba7df3aba02aaa9bf")
]

platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2024.2.0-intel_981.tar.bz2",
            "bb430763d0ee6029d6befa911605faf514ce83584933f64647c8fff527f5d136"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2024.2.0-intel_981.tar.bz2",
            "958dc668d49d2ae9dbe0f0e55f8f5025b3e280be0a5b294a3898bc6efbc74627"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2024.2.0-intel_981.tar.bz2",
            "7bfef6c455ae87a034e6efef1bbbbd7079875fcb4bdb3d5edbda950d1a1f0ee7"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/icc_rt-2024.2.1-intel_1079.tar.bz2",
            "3f5eb6990d6f804f6af0074f9ac6744a641005ababb22390e288c5b3f593748d"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2024.2.0-intel_981.tar.bz2",
            "a9b1c6fa0547f2c28a5b1b560fd656859af30933259f1c2b3e30f1bec5d9b259"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2024.2.0-intel_981.tar.bz2",
            "7b39b7446b875408045a3b578ad467060db66be1c71dbbf25e1310c53a0857ea"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2024.2.0-intel_981.tar.bz2",
            "ab37ae3b142ea2cdd5bfed4389ea3299e66cc6da14e8751d8a609f970ae732ff"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2024.2.0-intel_981.tar.bz2",
            "1a33749a1696c0c0f2d572b76a98891c032e8e58354d6969036451f0848dff05"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2024.2.0-intel_981.tar.bz2",
            "db46064dbf0dbc096d92d8368ef8172ae335001b81055840c97fcfda3d09d64d"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2024.2.0-intel_981.tar.bz2",
            "98a5503a47feb2e72b2fce045d7edc177c333828b5eee3dd337dfd7441c8c11a"
        ),


        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2024.2.0-intel_663.tar.bz2",
            "f480deb23179471b5f05de50b06ad984702be25e66d58ef614b804b781a3613e"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2024.2.0-intel_663.tar.bz2",
            "e3c37c75aa870aa8daa32e6cbfa6e34639f7e6fe6a67fc4b34fa2a94a497df15"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2024.2.0-intel_663.tar.bz2",
            "82a403a7ae930e9ace33472fa9f0b7652f292f106d2d290668643d57207783d1"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2024.2.0-intel_663.tar.bz2",
            "08426f44ca13ff81030a8ce8d777f167d06b9194df8b5635fd143c0848bac3f2"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2024.2.0-intel_663.tar.bz2",
            "2e29ca36f199bafed778230b054256593c2d572aeb050389fd87355ba0466d13"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2024.2.0-intel_663.tar.bz2",
            "1d622d465ed0eaf583e30a0351873437e58952b71553fbb68f28ca4fc92bb9d9"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2024.2.0-intel_663.tar.bz2",
            "d7da0657275e1640b15f8640f321028b1c9576eca42bf59674e1d286f5cba937"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2024.2.0-intel_663.tar.bz2",
            "2dba874c8fd0ebb2f4b005e937241de9706b028ba11a0667abeafa0edfad6956"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2024.2.0-intel_663.tar.bz2",
            "4e4eb4b88d0715d8cc2c7b7a937d579da97ea099be7bf7f8b75968a1c32d6aa5"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2024.2.0-intel_663.tar.bz2",
            "c401d5e830bd3edf70c07fb1dc25067e80979d6aa7d971ec4391541c6dbd7df8"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2024.2.0-intel_663.tar.bz2",
            "2c369bdd91eba6b70bee073ef43fd27730939852d2bf40ed10a7cc16ef44691b"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2024.2.0-intel_663.tar.bz2",
            "7dba88f56711ff66fd4eb188b70e55e79ecb385842a85459d96d4c196304be55"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2024.2.0-intel_663.tar.bz2",
            "43e1e0363dfc22cb9dbea61306324b63f4b1b7a90fc1cf0f5cfb6400698dee33"
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

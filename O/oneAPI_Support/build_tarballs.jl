using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.5.1"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "cfc99dde28eb8c41cdc30347a9859b70a6540d3d")
]

platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp-cpp-rt-2024.1.0-intel_963.tar.bz2",
            "ab3ef09509893100233de23d5af8bd3872bfc46c79cc9c9d10e21d5a2003c389"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_impl_linux-64-2024.1.0-intel_963.tar.bz2",
            "84cccd5d33f93a73d2925e438066f3303f1caf5201cc326beabe46a30f01dd77"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_linux-64-2024.1.0-intel_963.tar.bz2",
            "a11c55e5ecb711c431335923101b3c93dbe5528644a8f94e08b0b734bcd0c6ea"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/icc_rt-2024.1.0-intel_963.tar.bz2",
            "166441df7305a80aa8ef9b951b9d79f5a74d48d56e4a0747770d3343caa405fc"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lib-rt-2024.1.0-intel_963.tar.bz2",
            "7ceb4091d88d792ebb05940dd9bd6f3cc71e0a59cb893f00c4494ee02a9c1ca6"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lic-rt-2024.1.0-intel_963.tar.bz2",
            "3794d69ff625403ee002f4836d68a51fa06f68fb32082596b724d075a4af1e14"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-openmp-2024.1.0-intel_963.tar.bz2",
            "6ab48343ca3c15768c33ca50ba2f0266e8d300b6755a685ae1aa5149fbe008e9"
        ),


        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-2024.1.0-intel_691.tar.bz2",
            "419f0522a7ffa1133deddaa8eec5d8f9a383993b118cfaa2e897c439200549ef"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-2024.1.0-intel_691.tar.bz2",
            "def8ca30d0560a712e5f010f26da26d723c6bc9148124d8a63f6d2fb64fd3e38"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-dpcpp-2024.1.0-intel_691.tar.bz2",
            "abae8c0903e438bce8acfdf2b790d10863669490a87f19a908942268d5fabc82"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-dpcpp-2024.1.0-intel_691.tar.bz2",
            "810c7ca1818101246d7df572f6e6702ac727b5a2a7eec9b7bb75a531e54f5eb5"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-include-2024.1.0-intel_691.tar.bz2",
            "e36b2e74f5c28ff91565abe47a09dc246c9cf725e0d05b5fb08813b4073ea68b"
        ),

        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-blas-2024.1.0-intel_691.tar.bz2",
            "fb334c846ad568653898a633a1a34ed1e595955a3a706776679931b9d7e10c45"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-lapack-2024.1.0-intel_691.tar.bz2",
            "fb06906f5b4da3fdd907ab9956f6fb74f05ca58f2b8a9204dd4dd4cfbb5f1648"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-sparse-2024.1.0-intel_691.tar.bz2",
            "fae28f1831b1f7ea7b449b814a6a80219ba84ed779250a1826cad4397725fe8e"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-datafitting-2024.1.0-intel_691.tar.bz2",
            "c7ef31e06d11c61cc87e8bb5341172a074c22b31f9db8e0e9a3f190871d9ac81"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-dft-2024.1.0-intel_691.tar.bz2",
            "29ae425989cb77e8fa67b9dcdc4234337cfd947eddf2481cd2cfcb4ce36c2cf0"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-rng-2024.1.0-intel_691.tar.bz2",
            "34fae52fdef4c7c01ca2f64055d8eea6305b5fef9c18ae3a06ce1d79b0f27f25"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-stats-2024.1.0-intel_691.tar.bz2",
            "50c018d56793d5b2e6848e7ea3099485af1e9a752bb3c675b22bf1709579d8e0"
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/onemkl-sycl-vm-2024.1.0-intel_691.tar.bz2",
            "3698ecae3d12c074864bc526961b74b471b3cdb42982953ab603a61b6e686608"
        ),
        ArchiveSource(
            "https://anaconda.org/intel/tbb/2021.12.0/download/linux-64/tbb-2021.12.0-intel_495.tar.bz2",
            "ca912130d808de691ae4a80f7888a41fb883d577bc7e36722a09c792d2cefdf6"
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

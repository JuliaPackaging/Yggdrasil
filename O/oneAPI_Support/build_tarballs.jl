using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.2.2"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl", "ab65719ed81a1237ef7afc7b3a0afb36bd9f3c36")
]

platform_sources = Dict(
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp-cpp-rt-2023.0.0-intel_25370.tar.bz2",
            "8aa30359fd1c0939cdcf0c36fa76e2fb07c8384a1f51acc2ccd563289c845010";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_impl_linux-64-2023.0.0-intel_25370.tar.bz2",
            "e4d53ac4000f4a3774d1860561ba1305791b7254173e8b0057845aedc1a3aa99";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_linux-64-2023.0.0-intel_25370.tar.bz2",
            "b271aff70c99acc24f3ffccef4c246a943541dac98059c824a2f0f8b1c68df49";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/icc_rt-2023.0.0-intel_25370.tar.bz2",
            "189ec80a95810ca2d2f4d8659792d7cc662872b0aa5dabb1d803e684eca1f072";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lib-rt-2023.0.0-intel_25370.tar.bz2",
            "10ae52d6480ce511b1b345391d2246140ba92e3f34c9fb2fdb72b88a6f2d0f66";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lic-rt-2023.0.0-intel_25370.tar.bz2",
            "f3d4270cd182efd8c795c669d6fb95b046172acacf003921bd7baef70d595540";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-opencl-rt-2023.0.0-intel_25370.tar.bz2",
            "6f236af7c3c6e1b6026052b60799089f49548cdcd2abdaf56b2c335df0d7ab20";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-openmp-2023.0.0-intel_25370.tar.bz2",
            "0eae400bf40e9c5d6cddf1750ce223602fa773864fdb05a794f78b07b97c54e3";
        ),


        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-2023.0.0-intel_25398.tar.bz2",
            "b7ccc9f8a5d1c6c41a1a13fce3a7af4226f1382920765284d5d64ba6f86db53d";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-2023.0.0-intel_25398.tar.bz2",
            "d9c314768a67966c9cb6258653557daaa4bc42037a18f39ab7dd04cb3961f857";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-dpcpp-2023.0.0-intel_25398.tar.bz2",
            "4a53862549650dc5950884cf676a02d0a3334205419c0449eba3b375038b44c7";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-dpcpp-2023.0.0-intel_25398.tar.bz2",
            "d8029d7636f10e60bc66e93848561bb986df40c621b659a8e9346fdb24cb6851";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-include-2023.0.0-intel_25398.tar.bz2",
            "ac06e55127ab6389d516fb07665862a315ae6dfc1331ee6e8248ce19a26cd7fd";
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
for lib in mkl_sycl mkl_intel_ilp64 mkl_sequential mkl_core sycl \
           pi_level_zero pi_opencl OpenCL svml irng imf intlc; do
    cp -a lib/lib${lib}*.so* ${libdir}
done

cd oneAPI.jl/deps

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=RelWithDebInfo)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
# XXX: use the Clang version to work around an issue with the SYCL headers
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

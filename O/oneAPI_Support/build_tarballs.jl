using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.1"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl", "c9f21108139d0b186e83f183aacc4df9a65b895a")
]

platform_sources = Dict(
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp-cpp-rt-2022.1.0-intel_3768.tar.bz2",
            "1472da83f109dbead10835e49d204035272b9727eb71863e5a64688e13e6bacf";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_impl_linux-64-2022.1.0-intel_3768.tar.bz2",
            "4ff8f0a0c482aa6ffeb419fe9d0d38a697d2db8d86e65ca499f47d5d68747436";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/dpcpp_linux-64-2022.1.0-intel_3768.tar.bz2",
            "96a13c1fb673bcb0b6b0ddb6c436312113292d7ea21a55395a7efa34e70af0b1";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/icc_rt-2022.1.0-intel_3768.tar.bz2",
            "b81f4838a930d08edec2aab4d3eebd89ce3b321ca602792bcc9433926836da07";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lib-rt-2022.1.0-intel_3768.tar.bz2",
            "8c86ea88d46cb13b3b537203e15fc6e6ec2d803b7bd0bde8561d347b18ba426e";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-cmplr-lic-rt-2022.1.0-intel_3768.tar.bz2",
            "fd3b6a0e75f06b1bf22b070a7b61b09d2a3e9d9e01a64b60b746b35f45681acb";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-opencl-rt-2022.1.0-intel_3768.tar.bz2",
            "f4086002b4d5699dea78659777e412ef6c6ea2fa1d3984d135848f0b75144b81";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/intel-openmp-2022.1.0-intel_3768.tar.bz2",
            "498dc37ce1bd513f591b633565151c4de8f11a12914814f2bf85afebbd35ee23";
        ),


        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-2022.1.0-intel_223.tar.bz2",
            "31c225ce08d3dc129f0881e5d36a1ef0ba8dc9fdc0e168397c2ac144d5f0bf54";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-2022.1.0-intel_223.tar.bz2",
            "4e014e6ac31e8961f09c937b66f53d2c0d75f074f39abfa9f378f4659ed2ecbb";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-devel-dpcpp-2022.1.0-intel_223.tar.bz2",
            "25e38a5466245ce289c77a4bb1c38d26d3a4ec762b0207f6f03af361a3529322";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-dpcpp-2022.1.0-intel_223.tar.bz2",
            "79af3aa775168128054d8e2cb04717fea55b1779885d3472286106e1f24d0fc4";
        ),
        ArchiveSource(
            "https://conda.anaconda.org/intel/linux-64/mkl-include-2022.1.0-intel_223.tar.bz2",
            "704e658a9b25a200f8035f3d0a8f2e094736496a2169f87609f1cfed2e2eb0a9";
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
    BuildDependency("oneAPI_Level_Zero_Headers_jll")
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
                   products, dependencies; skip_audit=true, dont_dlopen=true,
                   preferred_gcc_version=v"8")
end

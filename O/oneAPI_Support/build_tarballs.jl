using BinaryBuilder, Pkg

name = "oneAPI_Support"
version = v"0.7.0"

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

generic_sources = [
    GitSource("https://github.com/JuliaGPU/oneAPI.jl",
              "fc225b0b0691ab3df0898ef29fe907a7728d52d0")
]

platform_sources = Dict(
    # these are the deps installed by Anaconda for dpcpp_linux-64 and mkl-devel-dpcpp
    # https://conda.anaconda.org/intel/linux-64
    Platform("x86_64", "linux"; libc="glibc") => [
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/compiler_shared-2025.0.0-intel_1169.tar.bz2",
            "d31c89f3ffcc5b45366f7465b5a3411a3a2c529ecf72eebcc4c3a244f713d3eb"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp-cpp-rt-2025.0.0-intel_1169.tar.bz2",
            "2e74407b49fbf865462be995806aad4411ed992e1bee8404d2c75616db9c4ac6"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_impl_linux-64-2025.0.0-intel_1169.tar.bz2",
            "926f17c28168db9cb110d9803fc6037c0ea0b2bd37074ff4b21a1543f9e37777"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/dpcpp_linux-64-2025.0.0-intel_1169.tar.bz2",
            "fc652956fb8315ce23cb677678e788c519c817c1f82d1548a37bc8b90fab4994"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-rt-2025.0.0-intel_1169.tar.bz2",
            "9a6a149681d2cc87e0e818140c13af04c82fbfc0760a451db70cbbf07c560bde"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lib-ur-2025.0.0-intel_1169.tar.bz2",
            "95ec7e7014adfc2dda389008975e63a66338a235dbdef4a694989ed41ee5db75"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-cmplr-lic-rt-2025.0.0-intel_1169.tar.bz2",
            "865288f5b133f205692f88e38af5b1928f8e7ce0c99f9068be2a5d247c540067"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-opencl-rt-2025.0.0-intel_1169.tar.bz2",
            "fe38bfd3fcc01068aced409d34d64ee44e39831d2c4f1fcbf93bd0dee63f48ad"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-openmp-2025.0.0-intel_1169.tar.bz2",
            "bd2ef2fdac3e013bfdf71921e0c7d3e831b9f498d6303852539b2c447bd42790"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/intel-sycl-rt-2025.0.0-intel_1169.tar.bz2",
            "696aeb88832c8836d202bb4a434c5aa7ec145f92d62cc0a2d36fe10e77494a62"
        ),


        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-2025.0.0-intel_939.tar.bz2",
            "08018b7b73b8f1ceb2286d0fbf443bcf22ffd5fdff2010265f3cedbd0c3075d6"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-2025.0.0-intel_939.tar.bz2",
            "89fc99f696ee10291b39bd60f6104966ba07f750e4291830d3ed142e651ef0c3"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2025.0.0-intel_939.tar.bz2",
            "149c3d52dcc7db2d30329e686f721dc3addc017ba19034b7517c9d287f29f7d6"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-dpcpp-2025.0.0-intel_939.tar.bz2",
            "dfa829d9de4e7fbefacad3849a95957c020dc628b4ba010107918d62db4516be"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/mkl-include-2025.0.0-intel_939.tar.bz2",
            "e3c02344b0405d90c7b992493a081f1f763fa96493626a5da1fe7693040a486f"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-blas-2025.0.0-intel_939.tar.bz2",
            "89c7455152074e75cb8891ae95445e033f28243ca8ce0e54d7ef2a0890cd03dc"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-datafitting-2025.0.0-intel_939.tar.bz2",
            "08076e4d6395c68dc6cf125a9362cb2f3da1ec34d207a65bae483f57f3b05547"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-dft-2025.0.0-intel_939.tar.bz2",
            "d982cc495b4a19457c1f0382c312465628e774c627300a0530a3d674241f647b"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-lapack-2025.0.0-intel_939.tar.bz2",
            "875292b7539b528c027d8c4e78ebe809c3914359decc2fc1c66e7ed03c16feb1"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-rng-2025.0.0-intel_939.tar.bz2",
            "21911e846fa86f447eb25e251c02a813dc582c17b25ed0a74a934a2f89a5e80d"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-sparse-2025.0.0-intel_939.tar.bz2",
            "041968f53a5ae7c74193afb55dd57ffc20ad038cb4aeb33bdd39fe789e077ea8"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-stats-2025.0.0-intel_939.tar.bz2",
            "a7f2d5fb02a6999a5f189cd4a493471c6ab3e716d94ef4b9247653db723329d7"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/onemkl-sycl-vm-2025.0.0-intel_939.tar.bz2",
            "ee515cc5ad823d6980e519a9dc8c53dbac42e82ec178b33eeddca4eac2b36060"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-2022.0.0-intel_402.tar.bz2",
            "3b5abd11a7d2ae0162b8f40bea311e4566e3a6b02a9d4f0928134ae27d76aabd"
        ),
        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/tbb-devel-2022.0.0-intel_402.tar.bz2",
            "1b1029a9ceb00ef7116c3ec0c15a1de10a78eb27a2d3591b53a43a5ffd00ea9e"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/tcm-1.2.0-intel_589.tar.bz2",
            "5806a0b472192a350dc3f9865b980d8f1cc403c94445c77aa8fe4139aa121d99"
        ),

        ArchiveSource(
            "https://software.repos.intel.com/python/conda/linux-64/umf-0.9.0-intel_590.tar.bz2",
            "16a384288a8d2b66320aae06201eeecae2a424a7c6c3e5066ff97fe441cef7f9"
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
for lib in sycl svml irng imf intlc ur_loader ur_adapter \
           mkl_core mkl_intel_ilp64 mkl_sequential mkl_sycl \
           mkl_avx mkl_def umf tcm; do
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

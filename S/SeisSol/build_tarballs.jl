# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "SeisSol"
version = v"1.3.2"

sources = [
    GitSource("https://github.com/SeisSol/SeisSol.git",
              "20334d02af9c539a9cf7cc4cd03c3e2622104aea"),  # v1.3.2
    # Submodules at the commits pinned by v1.3.2 (GitSource does not fetch them)
    GitSource("https://github.com/SeisSol/yateto.git",
              "35001bd2acb2965a98171d79fe96e996936e60ed"),
    GitSource("https://github.com/TUM-I5/PUML2.git",
              "ce25087b25bc401b9b9377fef1de8f982018fd40"),
    GitSource("https://github.com/TUM-I5/ASYNC.git",
              "32f8b638ee925bb790558364e90dc57ac597cf6a"),
    GitSource("https://github.com/TUM-I5/utils.git",
              "3f1f476d42621dac848a952b50956b6e48f7c92b"),
    GitSource("https://github.com/TUM-I5/XdmfWriter.git",
              "dc6cead28eb7f2d049bb12d9451aeb1bf64eb25e"),
    GitSource("https://github.com/SeisSol/fty.git",
              "c6373291573b54ff744e1a50def6c7496371aa53"),
    # Generates the small-matrix kernels on aarch64
    GitSource("https://github.com/SeisSol/PSpaMM.git",
              "553f62e5db4c907d0b04ee41727a88dd47f0e5a4"),  # v0.3.1
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
for sub in yateto:yateto PUML2:PUML ASYNC:async utils:utils XdmfWriter:xdmfwriter fty:fty utils:async/submodules/utils; do
    mkdir -pv SeisSol/submodules/${sub#*:}
    cp -a ${sub%%:*}/. SeisSol/submodules/${sub#*:}
done
cd SeisSol
for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${patch}
done

# The Python 3.9 of the build environment needs a recent pip to find numpy wheels for musl
python3 -m pip install --upgrade pip
python3 -m pip install numpy setuptools ${WORKSPACE}/srcdir/PSpaMM

# Kernel generators, the same choice as in the SeisSol Docker image: libxsmm and PSpaMM on
# x86_64 (AVX2), PSpaMM on aarch64 (NEON)
cmake_args=()
if [[ "${target}" == *-mingw* ]]; then
    # No ASAGI/NetCDF and no generated kernels on Windows
    host_arch=noarch
    gemm_tools=none
    export CXXFLAGS="-D_USE_MATH_DEFINES"
    cmake_args+=(-DASAGI=OFF -DNETCDF=OFF -DCMAKE_CXX_STANDARD_LIBRARIES=-lws2_32)
elif [[ "${target}" == x86_64-* ]]; then
    host_arch=hsw
    gemm_tools="LIBXSMM,PSpaMM"
    cmake_args+=(-DASAGI=ON -DNETCDF=ON -DNetCDF_INCLUDE_DIR=${includedir} -DNetCDF_LIBRARY=${libdir}/libnetcdf.${dlext})
elif [[ "${target}" == *-apple-* ]]; then
    # clang cannot assemble the GNU syntax of PSpaMM's NEON kernels
    host_arch=neon
    gemm_tools=none
    cmake_args+=(-DASAGI=ON -DNETCDF=ON -DNetCDF_INCLUDE_DIR=${includedir} -DNetCDF_LIBRARY=${libdir}/libnetcdf.${dlext})
else
    host_arch=neon
    gemm_tools=PSpaMM
    cmake_args+=(-DASAGI=ON -DNETCDF=ON -DNetCDF_INCLUDE_DIR=${includedir} -DNetCDF_LIBRARY=${libdir}/libnetcdf.${dlext})
fi
export LIBXSMM_DIR=${host_prefix}

# std::filesystem, METIS and ParMETIS checks cannot run when cross-compiling
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHOST_ARCH=${host_arch} \
    -DGEMM_TOOLS_LIST=${gemm_tools} \
    -DORDER=4 \
    -DEQUATIONS=elastic \
    -DPRECISION=double \
    -DNUMA_AWARE_PINNING=OFF \
    -DMETIS_TEST_RUNS=1 \
    -D_METIS_64_BIT_INTEGER=0 \
    -DPARMETIS_TEST_RUNS=1 \
    -D_FILESYSTEM_NATIVE=1 \
    -DHDF5_PROVIDES_PARALLEL=ON \
    "${cmake_args[@]}"
cmake --build build --parallel ${nproc}

# The names of the executables contain the configuration; install them under fixed names
install -Dvm755 build/SeisSol_Release_d${host_arch}_4_elastic${exeext} ${bindir}/seissol${exeext}
install -Dvm755 build/SeisSol_proxy_Release_d${host_arch}_4_elastic${exeext} ${bindir}/seissol_proxy${exeext}
install_license LICENSE
"""

# std::filesystem needs macOS >= 10.15
sources, script = require_macos_sdk("11.0", sources, script)

# SeisSol generates its kernels for x86_64 (AVX2) and aarch64 (NEON) only
platforms = filter(p -> arch(p) in ("x86_64", "aarch64"), supported_platforms())
# SeisSol and its async submodule use Linux-only APIs (pthread_setaffinity_np, sys/sysinfo.h, open64)
filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

products = [
    ExecutableProduct("seissol", :seissol),
    ExecutableProduct("seissol_proxy", :seissol_proxy),
]

dependencies = [
    BuildDependency(PackageSpec(name = "Eigen_jll", version = v"3.4.1+0")),
    HostBuildDependency("libxsmm_jll"),
    Dependency("ASAGI_jll"; compat = "1.0.1"),
    Dependency("CompilerSupportLibraries_jll"; platforms = filter(!Sys.isapple, platforms)),
    Dependency("easi_jll"; compat = "1.7.0"),
    Dependency("HDF5_jll"; compat = "2.2.2"),
    Dependency("LLVMOpenMP_jll"; platforms = filter(Sys.isapple, platforms)),
    Dependency("NetCDF_jll"; compat = "401.1000.101"),
    Dependency("PARMETIS_jll"; compat = "4.0.9"),
    Dependency("yaml_cpp_jll"; compat = "0.9.0"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat = "1.10", preferred_gcc_version = v"9")

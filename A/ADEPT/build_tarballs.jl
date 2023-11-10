# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "ADEPT"
version = v"1.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/mgawan/ADEPT.git",
        "166e38b234fd4a6c1e756348eee4253b4ed281ce",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ADEPT
install_license LICENSE
mkdir build
cd build
export CUDA_HOME=${WORKSPACE}/destdir/cuda
export PATH=${PATH}:${CUDA_HOME}/bin
export CUDACXX=${CUDA_HOME}/bin/nvcc
ln -s ${WORKSPACE}/destdir/cuda/lib ${WORKSPACE}/destdir/cuda/lib64
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DADEPT_USE_PYTHON=OFF \
      -DBUILD_EXAMPLES=ON \
      -DBUILD_TESTS=OFF ..
cmake --build . --parallel ${nproc} --target all
install -Dvm 755 "adept/libadept_lib_shared.${dlext}" "${libdir}/libadept_lib_shared.${dlext}"
cd examples 
for dir in "asynch_protein" "asynch_sw" "multi_gpu" "multigpu_protein" "simple_sw"; do
    install -Dvm 755 "${dir}/${dir}${exeext}" "${bindir}/${dir}${exeext}" 
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

# The products that we will ensure are always built
products = [
    # Not adding multigpu_protein_scoreonly
    LibraryProduct("libadept_lib_shared", :libadept_lib_shared),
    ExecutableProduct("asynch_protein", :asynch_protein),
    ExecutableProduct("asynch_sw", :asynch_sw),
    ExecutableProduct("multi_gpu", :multi_gpu),
    ExecutableProduct("multigpu_protein", :multigpu_protein),
    ExecutableProduct("simple_sw", :simple_sw),
]

# Build ADEPT for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # Dependencies that must be installed before this package can be built
    cuda_deps = CUDA.required_dependencies(platform, static_sdk = true)
    dependencies = [
        Dependency(
            PackageSpec(
                name = "CompilerSupportLibraries_jll",
                uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
            ),
        ),
        cuda_deps...,
    ]

    build_tarballs(
        ARGS,
        name,
        version,
        sources,
        script,
        [platform],
        products,
        dependencies;
        lazy_artifacts = true,
        julia_compat = "1.9",
        preferred_gcc_version = v"10",
        augment_platform_block = CUDA.augment,
        skip_audit = true,
        dont_dlopen = true,
    )
end


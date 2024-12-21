# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, tags

name = "LightGBM"
version = v"4.3.0"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/LightGBM.git", "252828fd86627d7405021c3377534d6a8239dd69"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LightGBM
git submodule update --init --depth=1
git submodule update --checkout --depth=1

# https://github.com/microsoft/LightGBM/pull/6457
atomic_patch -p1 "$WORKSPACE/srcdir/patches/lightgbm-cmake-find-cuda.patch"

FLAGS=()
cmake_extra_args=()

if [[ "${bb_full_target}" == *"apple-darwin"* ]]; then
  cmake_extra_args+=(-DAPPLE=1 -DAPPLE_OUTPUT_DYLIB=1)
fi

if [[ "${bb_full_target}" == *-mingw* ]]; then
  cmake_extra_args+=(-DWIN32=1 -DMINGW=1)
  FLAGS+=(LDFLAGS="-no-undefined")
fi

if [[ "${bb_full_target}" == *-linux* ]]; then
  cmake_extra_args+=(-DUSE_GPU=1)
fi

if  [[ ("${bb_full_target}" == *-cuda*) && ("${bb_full_target}" != *-cuda+none*) ]]; then
  # nvcc writes to /tmp, which is a small tmpfs in our sandbox.
  # make it use the workspace instead
  export TMPDIR=${WORKSPACE}/tmpdir
  mkdir ${TMPDIR}
  export CUDA_PATH=${WORKSPACE}/destdir/cuda
  export PATH=$PATH:$CUDA_PATH/bin/

  cmake_extra_args+=(-DUSE_CUDA=1 -DCMAKE_CUDA_FLAGS="-L${CUDA_PATH}/lib -L${CUDA_PATH}/lib/stubs")
fi

cmake . \
  -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE=Release \
  "${cmake_extra_args[@]}"

make -j${nproc} "${FLAGS[@]}"
make install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
cuda_platforms = expand_cxxstring_abis(CUDA.supported_platforms(; min_version=v"11"))

# CUDA errors for other platforms
filter!(p -> (Sys.islinux(p) && arch(p) == "x86_64"), cuda_platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("lib_lightgbm", :lib_lightgbm),
    ExecutableProduct("lightgbm", :lightgbm),
]

all_platforms = [platforms; cuda_platforms]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, all_platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, all_platforms)),
    
    # GPU support is enabled via OpenCL and is hard to cross compile for other platforms
    Dependency(PackageSpec(name="OpenCL_jll", uuid="6cb37087-e8b6-5417-8430-1f242f1e46e4"); platforms=filter(Sys.islinux, all_platforms)),
    BuildDependency(PackageSpec(name="OpenCL_Headers_jll", uuid="a7aa756b-2b7f-562a-9e9d-e94076c5c8ee"); platforms=filter(Sys.islinux, all_platforms)),

    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.76.0", platforms=filter(Sys.islinux, all_platforms)),
]

for platform in all_platforms
    if platform in platforms && CUDA.is_supported(platform)
        platform["cuda"] = "none"
    end

    deps = [dependencies; CUDA.required_dependencies(platform; static_sdk=true)]

    should_build_platform(triplet(platform)) || continue

    # Build the tarballs, and possibly a `build.jl` as well.
    build_tarballs(ARGS, name, version, sources, script, [platform], products, deps; 
    julia_compat="1.6", preferred_gcc_version = v"8.1", augment_platform_block=CUDA.augment)
end

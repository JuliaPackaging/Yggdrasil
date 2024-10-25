using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Libxc_GPU"
version = v"7.0.0"
include("../sources.jl")

sources = [
    sources;
    # aarch64 binaries precompiled and hosted on GitHub, because BinaryBuilder
    # works on x86_64 architecture, and nvcc is not a cross-compiler
    GitSource("https://github.com/abussy/libxc_aarch64_gpu_binaries.git",
              "a075923825d39c5fd41b1550bcb8ba417d293e73")
]

# Bash recipe for building GPU version
# Notes:
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
script = raw"""

if [[ "${target}" == *aarch64* ]]; then
   cuda_ver=$(echo "$bb_full_target" | sed -n 's/.*cuda+\([0-9]\+\.[0-9]\+\).*/\1/p')
   cd $WORKSPACE/srcdir/libxc_aarch64_gpu_binaries/binaries
   unzip cuda-${cuda_ver}.zip

   cp -r products/lib/libxc.so* $prefix/lib
   chmod 555 $prefix/lib/libxc.so*
   cp -r products/include $prefix/include
   cp -r products/bin $prefix/bin

else
   cd $WORKSPACE/srcdir/libxc-*/

   mkdir libxc_build
   cd libxc_build

   mv ${WORKSPACE}/destdir/cuda/lib ${WORKSPACE}/destdir/cuda/lib64

   cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
       -DCMAKE_BUILD_TYPE=Release -DENABLE_XHOST=OFF -DBUILD_SHARED_LIBS=ON \
       -DENABLE_CUDA=ON -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
       -DBUILD_TESTING=OFF -DENABLE_FORTRAN=OFF \
       -DDISABLE_KXC=ON ..

   make -j${nproc}
   make install
fi
"""

# Override the default platforms
platforms = CUDA.supported_platforms(; min_version=v"11.4")
filter!(p -> arch(p) in ["x86_64", "aarch64"], platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build Libxc for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.8", augment_platform_block=CUDA.augment, preferred_gcc_version=v"8",
                   skip_audit=true, dont_dlopen=true)
end

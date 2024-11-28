using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Libxc_GPU"
version = v"6.1.0"
include("../sources.jl")

sources = [
    sources;
    DirectorySource("./bundled")
]

# Bash recipe for building GPU version
# Notes:
#   - 3rd and 4th derivatives (KXC, LXC) not built since gives a binary size of ~200MB
script = raw"""
cd $WORKSPACE/srcdir/libxc-*/

# Needed for Libxc 6.1.0 as these backport some fixes on libxc master
# On Libxc > 6.1.0 we can also remove the -DBUILD_TESTING=OFF
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmake-cuda.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/source-fixes.patch

mkdir libxc_build
cd libxc_build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release -DENABLE_XHOST=OFF -DBUILD_SHARED_LIBS=ON \
    -DENABLE_CUDA=ON -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc -DBUILD_TESTING=OFF \
    -DENABLE_FORTRAN=OFF -DDISABLE_KXC=ON ..

make -j${nproc}
make install
"""

augment_platform_block = CUDA.augment

# Override the default platforms
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libxc", :libxc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build Libxc for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.7", augment_platform_block,
                   skip_audit=true, dont_dlopen=true)
end

# bump

# build_tarballs.jl
# BinaryBuilder.jl recipe for AstraToolbox_jll (libastra)

using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, libc, tags

# Support platforms and helpers from Yggdrasil
if isfile(joinpath(@__DIR__, "../../platforms/cuda.jl"))
    include("../../platforms/cuda.jl")
else
    include(joinpath(@__DIR__, "platforms/cuda.jl"))
end

name = "AstraToolbox"
version = v"2.4.0"

# Sources: Astra Toolbox upstream GitSource and bundled Julia wrapper/patches
# Pinned commit hash ensures reproducibility.
sources = [
    GitSource("https://github.com/astra-toolbox/astra-toolbox.git",
              "bd0323e9b4b243ee90bca41341927b05e6e816c8"),
    DirectorySource("./bundled"),
]

# Bash recipe executed inside BinaryBuilder sandbox
script = raw"""
cd ${WORKSPACE}/srcdir/astra-toolbox*

# Apply patches from bundled/patches
if [ -d "${WORKSPACE}/srcdir/patches" ]; then
    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
        echo "Applying patch ${f}..."
        atomic_patch -p1 ${f}
    done
fi

# Install Julia C ABI wrapper files from bundled/wrapper
echo "Installing Julia C ABI wrapper..."
mkdir -p include/astra src
cp -fv ${WORKSPACE}/srcdir/wrapper/include/astra/julia_c_api.h include/astra/
cp -fv ${WORKSPACE}/srcdir/wrapper/src/julia_c_api.cpp src/

# Configure CUDA environment
export CUDA_HOME=${prefix}/cuda
export PATH=${CUDA_HOME}/bin:${PATH}

# Ensure lib64 symlink exists if SDK installed to lib
if [[ -d "${CUDA_HOME}/lib" && ! -d "${CUDA_HOME}/lib64" ]]; then
    ln -s lib "${CUDA_HOME}/lib64"
fi

# autogen and configure
cd build/linux
./autogen.sh

./configure --prefix=${prefix} \
            --host=${target} \
            --with-cuda=${CUDA_HOME} \
            --with-python=no \
            --with-matlab=no \
            --with-cuda-compute="all-major"

# Build libastra.la
make -j${nproc} libastra.la

# Install products
mkdir -p ${libdir}
cp -L .libs/libastra.so ${libdir}/libastra.so
cp -P .libs/libastra.so* ${libdir}/ || true

# Install license files
cd ${WORKSPACE}/srcdir/astra-toolbox*
install_license COPYING
if [ -f "${WORKSPACE}/srcdir/COPYING" ]; then
    install_license "${WORKSPACE}/srcdir/COPYING"
fi

# Clean up CUDA SDK from output prefix so it does not get bundled into the artifact
rm -rf ${prefix}/cuda
"""

# Products: exported shared library
products = [
    LibraryProduct("libastra", :libastra)
]

# Base platform: Linux x86_64 glibc
base_platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
]

# Targeted CUDA versions for initial recipe: CUDA 12 series (e.g. 12.4)
cuda_platforms = Platform[]
for p in base_platforms
    plat = deepcopy(p)
    plat["cuda"] = "12.4"
    push!(cuda_platforms, plat)
end

dependencies = [
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll")),
]

# Non-platform arguments passed to build_tarballs
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

for plat in cuda_platforms
    deps = BinaryBuilder.AbstractDependency[
        dependencies;
        CUDA.required_dependencies(plat)...
    ]

    build_tarballs(
        non_platform_ARGS,
        name,
        version,
        sources,
        script,
        [plat],
        products,
        deps;
        julia_compat = "1.10",
        augment_platform_block = CUDA.augment,
        preferred_gcc_version = v"10",
        dont_dlopen = true,
    )
end

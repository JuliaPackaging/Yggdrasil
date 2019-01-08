# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Julia"
version = v"1.0.3"

sources = [
    "https://github.com/JuliaLang/julia/releases/download/v$(version)/julia-$(version).tar.gz" =>
    "bfe9df6c52164c90b752cf6f167f69dffb5a0332658d05b0a42bfe18dbdf5e6a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/julia*/

BUILD_FLAGS=("prefix=${prefix}" USECCACHE=1)

# Set prefix-related paths
BUILD_FLAGS+=("prefix=${prefix}")

# Set arch-related flags
case ${target} in
    x86_64-*)
        BUILD_FLAGS+=("MARCH=x86-64" "JULIA_CPU_TARGET=generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)")
    ;;
    i686-*)
        BUILD_FLAGS+=("MARCH=pentium4" "JULIA_CPU_TARGET=pentium4;sandybridge,-xsaveopt,clone_all")
    ;;
    arm-*)
        BUILD_FLAGS+=("MARCH=armv7-a" "JULIA_CPU_TARGET=armv7-a;armv7-a,neon;armv7-a,neon,vfp4")
    ;;
    ppc64le-*)
        BUILD_FLAGS+=("JULIA_CPU_TARGET=pwr8")
    ;;
    aarch64-*)
        BUILD_FLAGS+=("MARCH=armv8-a" "JULIA_CPU_TARGET=generic")
    ;;
esac

# If we're compiling for Windows, then set XC_HOST
if [[ ${target} == *mingw* ]]; then
    BUILD_FLAGS+=("XC_HOST=${target}")
fi

# Make use of OpenBLAS and LLVM already prebuilt
for proj in BLAS LLVM; do
    BUILD_FLAGS+=(USE_SYSTEM_${proj}=1)
done
if [[ ${nbits} == 64 ]]; then
    BUILD_FLAGS+=(LIBBLASNAME=libopenblas LIBBLAS=-lopenblas64_)
else
    BUILD_FLAGS+=(LIBBLASNAME=libopenblas LIBBLAS=-lopenblas)
fi

make ${BUILD_FLAGS[@]} -j${nproc}
make ${BUILD_FLAGS[@]} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :glibc),
    Linux(:i686, :glibc),
    Windows(:x86_64),
    Windows(:i686),
]

# The products that we will ensure are always built
products(prefix) = Product[
    ExecutableProduct(prefix, "julia", :julia),
    LibraryProduct(prefix, "libjulia", :libjulia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/OpenBLAS-v0.3.5-0/build_OpenBLAS.v0.3.5.jl",
    "https://github.com/staticfloat/LLVMBuilder/releases/download/v6.0.1-4%2Bnowasm/build_LLVM.v6.0.1.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)


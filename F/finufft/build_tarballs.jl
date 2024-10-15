# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

include(joinpath(@__DIR__, "..", "..", "platforms", "microarchitectures.jl"))

name = "finufft"
version = v"2.3.0"
commit_hash = "fffdaeacb10d5d055ce5b313868a7e981cea594b"
# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/finufft.git", commit_hash)
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/finufft*/

mkdir build && cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DFINUFFT_FFTW_SUFFIX="" \
    -DFINUFFT_ARCH_FLAGS="" \
    -DFINUFFT_STATIC_LINKING="OFF"
cmake --build . --parallel $nproc
cmake --install .
"""

platforms = supported_platforms()
# xsimd library does not work with armv6, armv7, powerpc
filter!(p -> !(contains(arch(p), "armv") || contains(arch(p), "powerpc")), platforms)
# FreeBSD aarch64 does not build, remove for now
filter!(p -> !(p["os"]=="freebsd" && p["arch"]=="aarch64"), platforms)
# Expand for microarchitectures on x86_64 (library doesn't have CPU dispatching)
platforms = expand_cxxstring_abis(expand_microarchitectures(platforms, ["x86_64", "avx", "avx2", "avx512"]); skip=!Sys.iswindows)

augment_platform_block = """
    $(MicroArchitectures.augment)

    function augment_platform!(platform::Platform)
        # We augment only x86_64
        @static if Sys.ARCH === :x86_64
            augment_microarchitecture!(platform)
        else
            platform
        end
    end
    """

# The products that we will ensure are always built
products = [
    LibraryProduct("libfinufft", :libfinufft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

llvm_version = v"13.0.1+1"
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", preferred_llvm_version=llvm_version, julia_compat="1.6", augment_platform_block)

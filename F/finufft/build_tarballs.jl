# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

include(joinpath(@__DIR__, "..", "..", "platforms", "microarchitectures.jl"))

name = "finufft"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/flatironinstitute/finufft/archive/v$(version).zip", "042a96cab8a3c17a544125b7890616b1dd5eacd1b50ce0464617903b01bddd54")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/finufft*/

CFLAGS="-fopenmp -fPIC -O3 -funroll-loops -Iinclude"
if [[ "${target}" != *-freebsd* ]] && [[ "${target}" != *-apple-* ]]; then
    CFLAGS="${CFLAGS} -fcx-limited-range"
fi

# Overwrite LIBSFFT such that we do not require fftw3_threads or fftw3_omp for OMP support. Since the libraries in FFTW_jll already provide for threading, we do not loose anything.
# Make use of the -DFFTW_PLAN_SAFE flag to allow for multiple threads using finufft at the same time.
make lib \
    CC=${CC} \
    CXX=${CXX} \
    CFLAGS="${CFLAGS}" \
    CXXFLAGS="${CFLAGS} -std=c++14 -DFFTW_PLAN_SAFE" \
    LIBSFFT="-lfftw3 -lfftw3f -lm" \
    DYNLIB="lib/libfinufft.${dlext}"
install -Dvm 0755 "lib/libfinufft.${dlext}" "${libdir}/libfinufft.${dlext}"
"""

# Expand for microarchitectures on x86_64 (library doesn't have CPU dispatching)
# Tests on Linux/x86_64 yielded a slow binary with avx512 for some reason, so disable that
platforms = expand_cxxstring_abis(expand_microarchitectures(supported_platforms(), ["x86_64", "avx", "avx2"]); skip=!Sys.iswindows)

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

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6", augment_platform_block)

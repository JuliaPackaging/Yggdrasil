# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase

include(joinpath(@__DIR__, "..", "..", "platforms", "microarchitectures.jl"))

name = "ducc0"
version = v"0.27.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.mpcdf.mpg.de/mtr/ducc/-/archive/juliatest.tar.gz", "d8e3ce4cbc4212a69cf0ad9ddfbb46f056c5bc7c87d73ceb9c3f15d4a2da426c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ducc-*/julia
${CXX} ${CFLAGS} -O3 -I ../src/ ducc_julia.cc -Wfatal-errors -pthread -std=c++17 -fPIC -c
${CXX} ${CFLAGS} -O3 -o libducc_julia.${dlext} ducc_julia.o -Wfatal-errors -pthread -std=c++17 -shared -fPIC
install -Dvm 0755 "libducc_julia.${dlext}" "${libdir}/libducc_julia.${dlext}"
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
    LibraryProduct("libducc_julia", :libducc_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", julia_compat="1.6", augment_platform_block)

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "platforms", "microarchitectures.jl"))

name = "SHTns"
version = v"3.6.6"

# Collection of sources required to complete build (note to self: use `sha256sum` to generate the checksum from tarball) 
sources = [
    ArchiveSource("https://gricad-gitlab.univ-grenoble-alpes.fr/schaeffn/shtns/-/archive/v$(version)/shtns-v$(version).tar.gz",
                  "f060757ed6914c837cc2b251d370078e4c92b6894fef7aac189a9a1f5f1521a2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shtns*/
export CFLAGS="-fPIC -O3" #only -fPIC produces slow code on linux x86 and MacOS x86 (maybe others)

#remove lfftw3_omp library references, as FFTW_jll does not provide it
sed -i -e 's/lfftw3_omp/lfftw3/' configure

./configure --prefix=${prefix} --host=${target} --enable-openmp --enable-kernel-compiler=cc
make -j${nproc}
make install

mkdir -p ${libdir}
cc -fopenmp -shared -o "${libdir}/libshtns.${dlext}" *.o -lfftw3
rm "${prefix}/lib/libshtns_omp.a"

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# Expand for microarchitectures on x86_64 (library doesn't have CPU dispatching)
platforms = expand_microarchitectures(supported_platforms(), ["x86_64", "avx", "avx2", "avx512"])

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
    LibraryProduct("libshtns", :LibSHTns)
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
               julia_compat="1.6",
               preferred_gcc_version=v"10",
               augment_platform_block)

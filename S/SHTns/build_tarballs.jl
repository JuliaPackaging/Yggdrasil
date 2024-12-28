# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

YGGDRASILPATH = joinpath(@__DIR__, "..", "..")

include(joinpath(YGGDRASILPATH, "fancy_toys.jl"))
include(joinpath(YGGDRASILPATH, "platforms", "microarchitectures.jl"))
include(joinpath(YGGDRASILPATH, "platforms", "cuda.jl"))

name = "SHTns"
version_string = "3.7"
version = VersionNumber(version_string)

# Collection of sources required to complete build (note to self: use `sha256sum` to generate the checksum from tarball) 
sources = [
    ArchiveSource("https://gricad-gitlab.univ-grenoble-alpes.fr/schaeffn/shtns/-/archive/v$(version_string)/shtns-v$(version_string).tar.gz",
                  "6c727ccc4d15d3170c3e20ad2b8a721c8b1fd838b1944c7d7e515a4fce43f75c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shtns*/
export CFLAGS="-fPIC -O3" #only -fPIC produces slow code on linux x86 and MacOS x86 (maybe others)
export LDFLAGS=""

#remove lfftw3_omp library references, as FFTW_jll does not provide it
sed -i -e 's/lfftw3_omp/lfftw3/g' configure

#remove mtune and gencode flags, replace by nvcc -arch=all (good?)
sed -i -e '/-mtune=skylake/d' configure
sed -i -e 's/nvcc -std=c++11 \$nvcc_gencode_flags/nvcc -Xcompiler -fPIC -std=c++11 -arch=all/' configure

sed -i -e 's/lib64/lib/g' configure

configure_args="--prefix=${prefix} --host=${target} --enable-openmp --enable-kernel-compiler=cc "
link_flags="-lfftw3 -lm "

if [[ -d "${prefix}/cuda" ]]; then
    export CUDA_PATH="$prefix/cuda"
    export PATH=$CUDA_PATH/bin:$PATH
    LDFLAGS+="-L$CUDA_PATH/lib -L$CUDA_PATH/lib/stubs"
    configure_args+="--enable-cuda"
    link_flags+="-lcuda -lnvrtc -lcudart"
fi

./configure $configure_args
make -j${nproc} 
rm *.a
mkdir -p ${libdir}
cc -fopenmp -shared $CFLAGS $LDFLAGS -o "${libdir}/libshtns.${dlext}" *.o $link_flags

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

cpu_platforms = supported_platforms()
cuda_platforms = CUDA.supported_platforms(; min_version=v"11.5") #v11.4 does not have -arch=all available

filter!(p -> arch(p) != "aarch64", cuda_platforms) #doesn't work

platforms = [cuda_platforms;cpu_platforms]

# The products that we will ensure are always built
products = [
    LibraryProduct("libshtns", :LibSHTns)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs
for platform in platforms
    if Sys.islinux(platform) && (arch(platform) == "x86_64") && (libc(platform) == "glibc")
        if !haskey(platform,"cuda")
            platform["cuda"] = "none"
        end
    end
    should_build_platform(triplet(platform)) || continue
    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; CUDA.required_dependencies(platform)];
                julia_compat = "1.6",
                lazy_artifacts=true,
                preferred_gcc_version = v"10",
                augment_platform_block = CUDA.augment, dont_dlopen=true, skip_audit=true)
end

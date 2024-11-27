# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

YGGDRASILPATH = joinpath(@__DIR__, "..", "..")

include(joinpath(YGGDRASILPATH, "fancy_toys.jl"))
include(joinpath(YGGDRASILPATH, "platforms", "microarchitectures.jl"))
include(joinpath(YGGDRASILPATH, "platforms", "cuda.jl"))

name = "SHTns"
version = v"3.7"
version_string = version.patch == 0 ? string(version.major)*"."*string(version.minor) : string(version)

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

#remove cuda arch specification and test
# sed -i -e '/any compatible gpu/d' configure 
# sed -i -e 's/nvcc -std=c++11 \$nvcc_gencode_flags/nvcc -Xcompiler -fPIC -std=c++11/' configure

sed -i -e 's/lib64/lib/g' configure
sed -i -e 's/nvcc -std=c++11/nvcc -Xcompiler -fPIC -std=c++11/' configure

configure_args="--prefix=${prefix} --host=${target} --enable-openmp --enable-kernel-compiler=cc "
link_flags="-lfftw3 -lm "

if [[ $bb_full_target == *cuda* ]]; then
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

# Expand for microarchitectures on x86_64 (library doesn't have CPU dispatching)
cpu_platforms = expand_microarchitectures(supported_platforms(), ["x86_64", "avx", "avx2", "avx512"])

const augment_platform_block = """
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

const augment_platform_block_cuda = """
    using Base.BinaryPlatforms

    try
        using CUDA_Runtime_jll
    catch
        # during initial package installation, CUDA_Runtime_jll may not be available.
        # in that case, we just won't select an artifact.
    end

    # can't use Preferences for the same reason
    const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
    const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)
    Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "version")
    Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "local")
    const local_toolkit = something(tryparse(Bool, get(preferences, "local", "false")), false)

    function cuda_comparison_strategy(_a::String, _b::String, a_requested::Bool, b_requested::Bool)
        # if we're using a local toolkit, we can't use artifacts
        if local_toolkit
            return false
        end

        # if either isn't a version number (e.g. "none"), perform a simple equality check
        a = tryparse(VersionNumber, _a)
        b = tryparse(VersionNumber, _b)
        if a === nothing || b === nothing
            return _a == _b
        end

        # if both b and a requested, then we fall back to equality
        if a_requested && b_requested
            return Base.thisminor(a) == Base.thisminor(b)
        end

        # otherwise, do the comparison between the the single version cap and the single version:
        function is_compatible(artifact::VersionNumber, host::VersionNumber)
            if host >= v"11.0"
                # enhanced compatibility, semver-style
                artifact.major == host.major &&
                Base.thisminor(artifact) <= Base.thisminor(host)
            else
                Base.thisminor(artifact) == Base.thisminor(host)
            end
        end
        if a_requested
            is_compatible(b, a)
        else
            is_compatible(a, b)
        end
    end

    function augment_platform!(platform::Platform)

        if !@isdefined(CUDA_Runtime_jll)
            # don't set to nothing or Pkg will download any artifact
            platform["cuda"] = "none"
        end

        if !haskey(platform, "cuda")
            CUDA_Runtime_jll.augment_platform!(platform)
        end
        BinaryPlatforms.set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)

        @static if Sys.ARCH === :x86_64
            return augment_microarchitecture!(platform)
        else
            return platform
        end
        
    end
    """

cuda_platforms = expand_microarchitectures(CUDA.supported_platforms(), ["x86_64", "avx", "avx2", "avx512"])
# cuda_platforms = CUDA.supported_platforms()

filter!(p -> arch(p) != "aarch64", cuda_platforms) #doesn't work

platforms = [cuda_platforms; cpu_platforms]

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


# build_tarballs(ARGS, name, version, sources, script, cpu_platforms, products, dependencies;
#                 julia_compat = "1.6",
#                 preferred_gcc_version = v"10",
#                 augment_platform_block)


cuda_min_version = v"11"
cuda_max_version=nothing

for platform in cpu_platforms
    should_build_platform(triplet(platform)) || continue
    build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies;
                        julia_compat = "1.10",
                        preferred_gcc_version = v"10",
                        augment_platform_block)
    if Sys.islinux(platform) && (arch(platform) == "x86_64")
        cuda_versions = filter(v -> (isnothing(cuda_min_version) || v >= cuda_min_version) &&
                (isnothing(cuda_max_version) || v <= cuda_max_version),
        CUDA.cuda_full_versions)
        platformc = deepcopy(platform)
        for version in cuda_versions
            platformc["cuda"] = "$(version.major).$(version.minor)"
            should_build_platform(triplet(platformc)) || continue
            build_tarballs(ARGS, name, version, sources, script, [platformc], products, [dependencies; CUDA.required_dependencies(platformc)];
                        julia_compat = "1.10",
                        preferred_gcc_version = v"10",
                        augment_platform_block = augment_platform_block_cuda, dont_dlopen=true, skip_audit=true)
        end
    end
end

# for platform in cpu_platforms
#     should_build_platform(triplet(platform)) || continue
#     build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies;
#                 julia_compat = "1.10",
#                 preferred_gcc_version = v"10",
#                 augment_platform_block = augment_platform_block_cuda)

# end
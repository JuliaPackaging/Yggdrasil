# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "PAPI"
version = v"7.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://bitbucket.org/icl/papi.git", "de96060998cd9fc77396c5e100e52e0ea1cdc3c3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd papi/src
if [[ "${target}" == *-musl* ]]; then
    CFLAGS="-D_GNU_SOURCE"
fi
export PAPI_CUDA_ROOT="${prefix}/cuda"
export CFLAGS
bash ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-ffsll \
    --with-perf-events \
    --with-walltimer=gettimeofday \
    --with-tls=__thread \
    --with-virtualtimer=times \
    --with-nativecc=${CC_FOR_BUILD}

make -j ${nproc}
make install
"""

augment_platform_block = CUDA.augment

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
 #    LibraryProduct("libpfm", :libpfm),
    LibraryProduct("libpapi", :libpapi)
]

cuda_versions_to_build = Any[
    v"10.2",
    v"11.0",
    "none"
]

# XXX: support only specifying major/minor version (JuliaPackaging/BinaryBuilder.jl#/1212)
cuda_versions = Dict(
    v"10.2" => v"10.2.89",
    v"11.0" => v"11.0.3",
)

cuda_platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
]

for cuda_version in cuda_versions_to_build, platform in platforms
    tag = cuda_version == "none" ? "none" : CUDA.platform(cuda_version)
    cuda_version != "none" && !(platform in cuda_platforms) && continue
    augmented_platform = Platform(arch(platform), os(platform);
                                  libc=platform.libc,
                                  cuda=tag)
    should_build_platform(triplet(augmented_platform)) || continue

    if cuda_version == "none"
        dependencies = []
    else
        if arch(platform)
            dependencies = [
                BuildDependency(PackageSpec(name="CUDA_full_jll",
                                            version=cuda_full_versions[cuda_version])),
                RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
            ]
        end
    end

    build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block)
end

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
    GitSource("https://bitbucket.org/icl/papi.git", "de96060998cd9fc77396c5e100e52e0ea1cdc3c3"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/papi

# Apply all our patches
if [ -d $WORKSPACE/srcdir/patches ]; then
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

cd src
if [[ "${target}" == *-musl* ]]; then
    CFLAGS="-D_GNU_SOURCE"
fi

COMPONENTS=()
if [[ -d "${prefix}/cuda" ]]; then
    COMPONENTS+=(cuda)
    export PAPI_CUDA_ROOT="${prefix}/cuda"
fi

if [[ ${target} == powerpc64le-* ]]; then
  CPU=POWER8
elif [[ ${target} == x86_64-* || ${target} == i686-* ]]; then
  CPU=x86
else
  CPU=arm
fi

echo "Building components: ${COMPONENTS[@]}"
export CFLAGS
bash ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-ffsll \
    --with-perf-events \
    --with-walltimer=gettimeofday \
    --with-tls=__thread \
    --with-virtualtimer=times \
    --with-shared-lib \
    --with-nativecc=${CC_FOR_BUILD} \
    --with-components="${COMPONENTS[@]}" \
    --with-CPU="${CPU}"

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

cuda_platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
]

for cuda_version in cuda_versions_to_build, platform in platforms
    tag = cuda_version == "none" ? "none" : CUDA.platform(cuda_version)
    cuda_version != "none" && !(platform in cuda_platforms) && continue
    augmented_platform = Platform(arch(platform), os(platform);
                                  libc=libc(platform),
                                  cuda=tag)
    if platform == Platform("powerpc64le", "linux"; libc = "glibc") && cuda_version == v"11.0"
        continue
    end
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = AbstractDependency[
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    ]
    if cuda_version != "none"
        if platform in cuda_platforms
            push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll",
                                                            version=CUDA.full_version(cuda_version))))
        end
    end


    build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block,
                   preferred_gcc_version=v"5")
end

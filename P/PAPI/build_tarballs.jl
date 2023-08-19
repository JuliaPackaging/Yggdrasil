# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "PAPI"
version = v"7.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/icl-utk-edu/papi.git", "cf3ef8872e30236a3d354e34a173e620738266b2"),
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

cuda_platforms = CUDA.supported_platforms()
filter!(p -> arch(p) != "aarch64", cuda_platforms)
filter!(p -> !(arch(p) == "powerpc64le" && p["cuda"] == "11.0"), cuda_platforms)

for platform in [platforms; cuda_platforms]
    should_build_platform(triplet(platform)) || continue

    dependencies = AbstractDependency[
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
        CUDA.required_dependencies(platform)...
    ]

    if platform in platforms && CUDA.is_supported(platform)
        platform["cuda"] = "none"
    end

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block=CUDA.augment,
                   preferred_gcc_version=v"5")
end

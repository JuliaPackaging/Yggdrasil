# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "PAPI"
version = v"7.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/icl-utk-edu/papi.git", "3ce9001dff49e1b6b1653ffb429808795f71a0bd"),
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

# These are the platforms we will build for by default
platforms = supported_platforms(; exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
 #    LibraryProduct("libpfm", :libpfm),
    LibraryProduct("libpapi", :libpapi),
    ExecutableProduct("papi_avail", :papi_avail),
    ExecutableProduct("papi_clockres", :papi_clockres),
    ExecutableProduct("papi_command_line", :papi_command_line),
    ExecutableProduct("papi_component_avail", :papi_component_avail),
    ExecutableProduct("papi_cost", :papi_cost),
    ExecutableProduct("papi_decode", :papi_decode),
    ExecutableProduct("papi_error_codes", :papi_error_codes),
    ExecutableProduct("papi_event_chooser", :papi_event_chooser),
    ExecutableProduct("papi_hardware_avail", :papi_hardware_avail),
    ExecutableProduct("papi_mem_info", :papi_mem_info),
    ExecutableProduct("papi_multiplex_cost", :papi_multiplex_cost),
    ExecutableProduct("papi_native_avail", :papi_native_avail),
    ExecutableProduct("papi_version", :papi_version),
    ExecutableProduct("papi_xml_event_info", :papi_xml_event_info),
]

# Compiling for CUDA 12.4 fails with
#     components/cuda/cupti_common.c: In function ‘cuptic_load_dynamic_syms’:
#     components/cuda/cupti_common.c:114:23: error: ‘CUPTIU_MAX_FILES’ undeclared (first use in this function)
#          char *found_files[CUPTIU_MAX_FILES];
#                            ^
cuda_platforms = CUDA.supported_platforms(; max_version=v"12.3.999")

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

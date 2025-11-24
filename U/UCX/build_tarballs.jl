# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "UCX"
version = v"1.18.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openucx/ucx.git",
                  "693d02837894b9c346c9f91b105e4aff6f259c09"),
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ucx*

# Apply all our patches
if [ -d $WORKSPACE/srcdir/patches ]; then
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi
./autogen.sh
update_configure_scripts --reconf

FLAGS=()
FLAGS+=(--prefix=${prefix})
FLAGS+=(--build=${MACHTYPE})
FLAGS+=(--host=${target})
FLAGS+=(--disable-debug)
FLAGS+=(--disable-assertions)
FLAGS+=(--disable-params-check)
FLAGS+=(--disable-static)
FLAGS+=(--disable-profiling)
FLAGS+=(--enable-shared)
FLAGS+=(--enable-mt)
FLAGS+=(--enable-frame-pointer)
FLAGS+=(--enable-cma)
FLAGS+=(--with-rdmacm=${prefix})

if [[ "${target}" != *aarch64* ]]; then
    FLAGS+=(--with-cuda=${prefix}/cuda)
fi

if [[ "${target}" == *x86_64* ]]; then
    FLAGS+=(--with-rocm=${prefix})
fi

./configure ${FLAGS[@]}

# For a bug in `src/uct/sm/cma/Makefile` that I did't have the time to look
# into, we have to build with `V=1`
make -j${nproc} V=1
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libuct", :libuct),
    LibraryProduct("libucm", :libucm),
    LibraryProduct("libucp", :libucp),
    LibraryProduct("libucs", :libucs),
    ExecutableProduct("ucx_info", :ucx_info),
    ExecutableProduct("ucx_perftest", :ucx_perftest),
    ExecutableProduct("ucx_read_profile", :ucx_read_profile),
]

# Dependencies that must be installed before this package can be built
# - librdmacm -> provided through rdma-core, need glibc 2.15
# - libibcm   -> legacy libibverbs
# - knem  -> kernel module
# - xpmem -> kernel module
# - CUDA -> Figure out how version dependent we are
#   - gdrcopy -> kernel module
# - ROCM -> TODO

cuda_version = v"11.4"
rocm_version = v"4.2.0"

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="NUMA_jll", uuid="7f51dc2b-bb24-59f8-b771-bb1490e4195d")),
    Dependency(PackageSpec(name="rdma_core_jll", uuid="69dc3629-5c98-505f-8bcd-225213cebe70")),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))),
    BuildDependency(PackageSpec(name="hsa_rocr_jll", version=rocm_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")

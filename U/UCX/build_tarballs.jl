# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "UCX"
version = v"1.9.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openucx/ucx/releases/download/v$(version)/ucx-$(version).tar.gz",
                  "a7a2c8841dc0d5444088a4373dc9b9cc68dbffcd917c1eba92ca8ed8e5e635fb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ucx-*
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-debug \
    --disable-assertions \
    --disable-params-check \
    --disable-static \
    --enable-mt \
    --enable-frame-pointer \
    --enable-cma \
    --with-rdmacm=${prefix}

# For a bug in `src/uct/sm/cma/Makefile` that I did't have the time to look
# into, we have to build with `V=1`
make -j${nproc} V=1
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="glibc"), https://github.com/openucx/ucx/issues/6239
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
# - librdmacm -> provided through rdma-core, need glic 2.15
# - libibcm   -> legacy libibverbs
# - knem  -> kernel module
# - xpmem -> kernel module
# - CUDA -> TODO
#   - gdrcopy -> kernel module
# - ROCM -> TODO

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="NUMA_jll", uuid="7f51dc2b-bb24-59f8-b771-bb1490e4195d")),
    Dependency(PackageSpec(name="rdma_core_jll", uuid="69dc3629-5c98-505f-8bcd-225213cebe70")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
	       preferred_gcc_version=v"5")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "UCX"
version = v"1.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openucx/ucx/releases/download/v1.7.0/ucx-1.7.0.tar.gz",
                  "6ab81ee187bfd554fe7e549da93a11bfac420df87d99ee61ffab7bb19bdd3371"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ucx-*
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-logging \
    --disable-debug \
    --disable-assertions \
    --disable-params-check \
    --disable-static
# For a bug in `src/uct/sm/cma/Makefile` that I did't have the time to look
# into, we have to build with `V=1`
make -j${nproc} V=1
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
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
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="NUMA_jll", uuid="7f51dc2b-bb24-59f8-b771-bb1490e4195d")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

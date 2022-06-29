# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lttng_ust"
version = v"2.12.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://lttng.org/files/lttng-ust/lttng-ust-2.12.2.tar.bz2", "bcd0f064b6ca88c72d84e760eac3472ae5c828411c634435922bee9fce359fc7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lttng-ust*
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man-pages --disable-examples
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("liblttng-ust-fd", :liblttng_ust_fd),
    LibraryProduct("liblttng-ust-dl", :liblttng_ust_dl),
    LibraryProduct("liblttng-ust-fork", :liblttng_ust_fork),
    LibraryProduct("liblttng-ust-libc-wrapper", :liblttng_ust_libc_wrapper),
    LibraryProduct("liblttng-ust-cyg-profile-fast", :liblttng_ust_cyg_profile_fast),
    LibraryProduct("liblttng-ust", :liblttng_ust),
    LibraryProduct("liblttng-ust-tracepoint", :liblttng_ust_tracepoint),
    LibraryProduct("liblttng-ust-pthread-wrapper", :liblttng_ust_pthread_wrapper),
    LibraryProduct("liblttng-ust-cyg-profile", :liblttng_ust_cyg_profile),
    LibraryProduct("liblttng-ust-ctl", :liblttng_ust_ctl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NUMA_jll", uuid="7f51dc2b-bb24-59f8-b771-bb1490e4195d"))
    Dependency(PackageSpec(name="URCU_jll", uuid="aa747835-a391-587f-982f-064ff03f7d29"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msquic"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/msquic.git", "a23f08040c3aefc004f608810b86b27098c49e7a"),
    ArchiveSource("http://lttng.org/files/lttng-ust/lttng-ust-2.12.2.tar.bz2", "bcd0f064b6ca88c72d84e760eac3472ae5c828411c634435922bee9fce359fc7"),
    ArchiveSource("http://lttng.org/files/lttng-tools/lttng-tools-2.12.4.tar.bz2", "d729f8c2373a41194f171aeb0da0a9bb35ac181f31afa7e260786d19a500dea1"),
    ArchiveSource("https://lttng.org/files/urcu/userspace-rcu-latest-0.13.tar.bz2", "cbb20dbe1a892c2a4d8898bac4316176e585392693d498766ccbbc68cf20ba20"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd userspace-rcu-0.13.0/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
cd ../lttng-ust-2.12.2/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man-pages --disable-examples
make
make install
cd ../lttng-tools-2.12.4/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-man-pages
make
make install
cd ../msquic/
git submodule update --init --recursive
mkdir build && cd build
cmake -G 'Unix Makefiles' ..
cmake --build .
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblttng-ctl", :lttng_ctl),
    LibraryProduct("liburcu-bp", :urcu_bp),
    LibraryProduct("liburcu-memb", :urcu_memb),
    LibraryProduct("liblttng-ust-libc-wrapper", :lttng_ust_libc_wrapper),
    LibraryProduct("liblttng-ust-cyg-profile", :lttng_ust_cyg_profile),
    LibraryProduct("liburcu-cds", :urcu_cds),
    LibraryProduct("liburcu", :urcu),
    LibraryProduct("liburcu-mb", :urcu_mb),
    LibraryProduct("liburcu-signal", :urcu_signal),
    LibraryProduct("liblttng-ust-ctl", :lttng_ust_ctl),
    LibraryProduct("liblttng-ust-fork", :lttng_ust_fork),
    LibraryProduct("liblttng-ust-dl", :lttng_ust_dl),
    LibraryProduct("liblttng-ust-tracepoint", :lttng_ust_tracepoint),
    LibraryProduct("liblttng-ust-cyg-profile-fast", :lttng_ust_cyg_profile_fast),
    LibraryProduct("liblttng-ust-pthread-wrapper", :lttng_ust_pthread_wrapper),
    LibraryProduct("liblttng-ust", :lttng_ust),
    LibraryProduct("liburcu-qsbr", :urcu_qsbr),
    LibraryProduct("liblttng-ust-fd", :lttng_ust_fd),
    LibraryProduct("liburcu-common", :urcu_common)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Popt_jll", uuid="e80236cf-ab1d-5f5d-8534-1d1285fe49e8"))
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"))
    Dependency(PackageSpec(name="NUMA_jll", uuid="7f51dc2b-bb24-59f8-b771-bb1490e4195d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")

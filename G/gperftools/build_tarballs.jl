# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gperftools"
version = v"2.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz", "1ee8c8699a0eff6b6a203e59b43330536b22bbcbe6448f54c7091e5efb0763c9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gperftools*/
if [[ "${target}" == *-linux-* ]]; then
    # Trick suggested in
    # https://github.com/gperftools/gperftools/blob/e5f77d6485bd2f6ce43862e3e57118b1bb97d30a/README
    export CXXFLAGS="-fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtcmalloc_debug", :libtcmalloc_debug),
    LibraryProduct("libtcmalloc", :libtcmalloc),
    LibraryProduct("libtcmalloc_and_profiler", :libtcmalloc_and_profiler),
    LibraryProduct("libtcmalloc_minimal", :libtcmalloc_minimal),
    LibraryProduct("libtcmalloc_minimal_debug", :libtcmalloc_minimal_debug),
    LibraryProduct("libprofiler", :libprofiler)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibUnwind_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

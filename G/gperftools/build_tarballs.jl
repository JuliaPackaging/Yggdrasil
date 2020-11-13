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

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
rm -f /opt/${MACHTYPE}/${MACHTYPE}/lib*/*.la

if [[ "${target}" == *-linux-* ]]; then
    # https://github.com/gperftools/gperftools/blob/e5f77d6485bd2f6ce43862e3e57118b1bb97d30a/README
    export CXXFLAGS="-fno-builtin-malloc -fno-builtin-calloc -fno-builtin-realloc -fno-builtin-free"
elif [[ "${target}" == *-apple-* ]]; then
    # https://github.com/Homebrew/homebrew-core/blob/5e8ab5f092bd4dfe9658bab6d86150e26a326de3/Formula/gperftools.rb#L28
    export CXXFLAGS=-D_XOPEN_SOURCE
elif [[ "${target}" == *-freebsd* ]]; then
    # Fix the error
    #   undefined reference to `backtrace_symbols'
    export LDFLAGS="-lexecinfo"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd")
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
    Dependency("LibUnwind_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

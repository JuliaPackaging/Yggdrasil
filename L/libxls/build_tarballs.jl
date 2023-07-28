# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libxls"
version = v"1.6.2"

sources = [
    ArchiveSource("https://github.com/libxls/libxls/releases/download/v$version/libxls-$version.tar.gz",
                  "5dacc34d94bf2115926c80c6fb69e4e7bd2ed6403d51cff49041a94172f5e371"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxls-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes 
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libxlsreader", :libxlsreader),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")

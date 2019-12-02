# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libxls"
version = v"1.5.2"

sources = [
    "https://github.com/libxls/libxls/releases/download/v$version/libxls-$version.tar.gz" =>
    "8d7e52d96ccc6c498e5de78c1988d9838d914eeeb94ac60208378340bd6e6aaa",
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")

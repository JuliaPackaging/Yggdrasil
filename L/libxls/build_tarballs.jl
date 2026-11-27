# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "libxls"
version = v"1.6.4"

sources = [
    ArchiveSource("https://github.com/libxls/libxls/releases/download/v$version/libxls-$version.tar.gz",
                  "064ee1da6cf3d481d8af4a936e0e0ce0190114e468fb7dfef5a81610746081e0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxls-*/
# libxls 1.6.3 adds -D_spawnv=spawnv to CFLAGS on mingw, which conflicts with
# the spawnv declaration in mingw-w64's process.h when compiling xls2csv.
sed -i 's/-D_spawnv=spawnv//' configure
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

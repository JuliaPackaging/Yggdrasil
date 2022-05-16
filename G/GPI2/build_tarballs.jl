# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GPI2"
version = v"1.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cc-hpc-itwm/GPI-2/archive/refs/tags/v$(version).tar.gz", "4dac7e9152694d2ec4aefd982a52ecc064a8cb8f2c9eab0425428127c3719e2e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd GPI-2-*
./autogen.sh
./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} --without-fortran --with-ethernet
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libGPI2-stats", :libGPI2_stats),
    LibraryProduct("libGPI2-dbg", :libGPI2_dbg),
    LibraryProduct("libGPI2", :libGPI2),
    ExecutableProduct("gaspi_logger", :gaspi_logger),
    FileProduct("bin/gaspi_run", :gaspi_run),
    FileProduct("bin/gaspi_cleanup", :gaspi_cleanup),
    FileProduct("bin/ssh.spawner", :ssh_spawner),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

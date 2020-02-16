# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NetCDF"
version = v"4.7.3"

# Collection of sources required to complete build
sources = [
    FileSource("https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-$version.tar.gz", "8e8c9f4ee15531debcf83788594744bd6553b8489c06a43485a15c93b4e0448b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-c-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Set equal to the supported platforms in HDF5
platforms = [
    Linux(:x86_64),
    Linux(:i686),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:aarch64, libc=:glibc),
    MacOS(),
    Windows(:x86_64),
    Windows(:i686),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdf", :libnetcdf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "HDF5_jll",
    "Zlib_jll",
    "LibCURL_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

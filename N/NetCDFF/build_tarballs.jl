# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NetCDFF"
version = v"4.6.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.unidata.ucar.edu/netcdf-fortran/$(version)/netcdf-fortran-$(version).tar.gz",
                  "b50b0c72b8b16b140201a020936aa8aeda5c79cf265c55160986cd637807a37a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-fortran*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    # Manually build shared library for Windows
    gfortran -shared -fPIC -o ${libdir}/libnetcdff.${dlext} -Wl,$(flagon --whole-archive) ${prefix}/lib/libnetcdff.a -Wl,$(flagon --no-whole-archive) -lnetcdf
fi
# Remove static libraries
rm ${prefix}/lib/*.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdff", :libnetcdff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="400.902.5"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Note: for some reason GCC 4.8 is still linked to glibc 2.12, we
               # need to use GCC 5 to have glibc 2.17.
               julia_compat="1.6", preferred_gcc_version=v"5")

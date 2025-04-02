# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NetCDFF"
version = v"4.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.unidata.ucar.edu/netcdf-fortran/$(version)/netcdf-fortran-$(version).tar.gz",
                  "df26b99d9003c93a8bc287b58172bf1c279676f8c10d6dd0daf8bc7204877096"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-fortran*
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
#TODO platforms = [
#TODO     Platform("x86_64", "linux"; libc = "glibc"),
#TODO     Platform("aarch64", "linux"; libc="glibc"),
#TODO     Platform("x86_64", "macos"),
#TODO     Platform("aarch64", "macos"),
#TODO     Platform("i686", "windows"),
#TODO     Platform("x86_64", "windows"),
#TODO ]
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdff", :libnetcdff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Without OpenMPI as build dependency the build fails on 32-bit
    # platforms. Other packages (e.g. GDAL_jll) have the same problem
    # and solve it in the same way.
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version=v"4.1.8"); platforms=filter(p -> nbits(p)==32, platforms)),
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="401.900.300"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Note: for some reason GCC 4.8 is still linked to glibc 2.12, we
               # need to use GCC 5 to have glibc 2.17.
               julia_compat="1.6", preferred_gcc_version=v"5")

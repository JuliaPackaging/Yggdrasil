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

if [[ ${target} == x86_64-linux-musl ]]; then
    # see
    # https://github.com/JuliaPackaging/Yggdrasil/blob/48af117395188f48d361a46ea929ee7563d9c2e4/A/ADIOS2/build_tarballs.jl

    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
fi

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir} -lnetcdf"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # Manually build shared library for Windows
    ${FC} -shared -fPIC -o ${libdir}/libnetcdff.${dlext} -Wl,$(flagon --whole-archive) ${prefix}/lib/libnetcdff.a -Wl,$(flagon --no-whole-archive) -lnetcdf
fi

# Remove static libraries
rm ${prefix}/lib/*.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
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
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version=v"4.1.8");
                    platforms=filter(p -> (nbits(p)==32 || Sys.isfreebsd(p)), platforms)),
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="401.900.300"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Note: for some reason GCC 4.8 is still linked to glibc 2.12, we need
# to use GCC 5 to have glibc 2.17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")

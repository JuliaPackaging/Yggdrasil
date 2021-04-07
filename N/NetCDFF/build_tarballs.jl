# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NetCDFF"
version = v"4.5.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.5.3.tar.gz", "c6da30c2fe7e4e614c1dff4124e857afbd45355c6798353eccfa60c0702b495a")
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
    Platform("x86_64", "macos"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdff", :libnetcdff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NetCDFF"
version = v"4.5.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v$(version).tar.gz",
                  "1a8613cb639e83e2df5a8e6c21fa48a0c64b053c244abddecec66cfcac03a48a"),
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
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="400.802.101"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # `MbedTLS_jll` is an indirect dependency through NetCDF, we need to specify
    # a compatible build version for this to work.
    BuildDependency(PackageSpec(; name="MbedTLS_jll", version=v"2.24.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

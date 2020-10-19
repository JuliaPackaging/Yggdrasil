# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "NetCDF"
version = v"4.7.4"

# Collection of sources required to build NetCDF
sources = [
    ArchiveSource("https://github.com/Unidata/netcdf-c/archive/v$(version).zip",
                  "170c9c9020f8909811b06e1034d5ea9288b3d5bd90793e3dd27490191faa7566")
]

# HDF5.h in /workspace/artifacts/805ccba77cd286c1afc127d1e45aae324b507973/include
# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-c-*

export CPPFLAGS="-I$prefix/include"
export LDFLAGS="-L${libdir}"

if [[ ${target} == *-mingw* ]]; then
   export LDFLAGS="-L${libdir} -lhdf5-0 -lhdf5_hl-0 -lcurl-4"

   if [ ! -f ${WORKSPACE}/destdir/bin/libzlib1.dll ]; then
       ln -s ${WORKSPACE}/destdir/bin/libz.dll ${WORKSPACE}/destdir/bin/libzlib1.dll
   fi

   ./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}  --disable-utilities --enable-shared --disable-static

   # linking fails with: "libtool:   error: can't build x86_64-w64-mingw32 shared library unless -no-undefined is specified"
   # unless -no-undefined is added to LDFLAGS
   make LDFLAGS="-no-undefined -L$prefix/bin -lhdf5-0 -lhdf5_hl-0 -lcurl-4" -j${nproc}

elif [[ "${target}" == *-apple-* ]]; then
    # this file is referenced by hdf.h by not installed
    touch /workspace/destdir/include/features.h

    if [ ! -f ${libdir}/libhdf5.dylib ]; then
        ln -s ${libdir}/libhdf5.*.dylib ${libdir}/libhdf5.dylib
    fi

    if [ ! -f ${libdir}/libhdf5_hl.dylib ]; then
        ln -s ${libdir}/libhdf5_hl.*.dylib ${libdir}/libhdf5_hl.dylib
    fi

   ./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}  --disable-utilities --enable-shared --disable-static
   make -j${nproc}
else
    # do not exist on Platform("x86_64", "linux")
    if [ ! -f ${libdir}/libhdf5.so ]; then
        ln -s ${libdir}/libhdf5.so.* ${libdir}/libhdf5.so
    fi

    if [ ! -f ${libdir}/libhdf5_hl.so ]; then
        ln -s ${libdir}/libhdf5_hl.so.* ${libdir}/libhdf5_hl.so
    fi

   ./configure --prefix=$prefix --build=${MACHTYPE} --host=${target}  --disable-utilities --enable-shared --disable-static
   make -j${nproc}
fi

make install
nc-config --all
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Set equal to the supported platforms in HDF5
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    # HDF5_jll on armv7l should use the same glibc as the root filesystem
    # before it can be used
    # https://github.com/JuliaPackaging/Yggdrasil/pull/1090#discussion_r432683488
    # Platform("armv7l", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdf", :libnetcdf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("HDF5_jll"),
    Dependency("Zlib_jll"),
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

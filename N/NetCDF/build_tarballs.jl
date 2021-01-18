# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.

name = "NetCDF"
version = v"400.700.400"
upstream_version = v"4.7.4"

# Collection of sources required to build NetCDF
sources = [
    ArchiveSource("https://github.com/Unidata/netcdf-c/archive/v$(upstream_version).zip",
                  "170c9c9020f8909811b06e1034d5ea9288b3d5bd90793e3dd27490191faa7566")
]

# HDF5.h in /workspace/artifacts/805ccba77cd286c1afc127d1e45aae324b507973/include
# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-c-*

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export LDFLAGS_MAKE="${LDFLAGS}"

if [[ ${target} == *-mingw* ]]; then
    export LIBS="-lhdf5-0 -lhdf5_hl-0 -lcurl-4 -lz"
    # linking fails with: "libtool:   error: can't build x86_64-w64-mingw32 shared library unless -no-undefined is specified"
    # unless -no-undefined is added to LDFLAGS
    LDFLAGS_MAKE="${LDFLAGS} ${LIBS} -no-undefined"

elif [[ "${target}" == *-apple-* ]]; then
    # this file is referenced by hdf.h by not installed
    touch ${includedir}/features.h
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-utilities \
    --enable-shared \
    --disable-static
make LDFLAGS="${LDFLAGS_MAKE}" -j${nproc}
make install
nc-config --all
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Set equal to the supported platforms in HDF5
platforms = [
    Platform("x86_64", "linux"),
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
    Dependency(PackageSpec(name="HDF5_jll", version="1.12.0")),
    Dependency("Zlib_jll"),
    Dependency("LibCURL_jll"),
    # The following libraries are dependencies of LibCURL_jll which is now a
    # stdlib, but the stdlib doesn't explicitly list its dependencies
    Dependency("LibSSH2_jll"),
    Dependency("MbedTLS_jll"),
    Dependency("nghttp2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

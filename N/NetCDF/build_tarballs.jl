# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.

name = "NetCDF"
upstream_version = v"4.9.2"

# Offset to add to the version number.  Remember to always bump this.
version_offset = v"0.2.6"

version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build NetCDF
sources = [
    ArchiveSource("https://downloads.unidata.ucar.edu/netcdf-c/$(upstream_version)/netcdf-c-$(upstream_version).tar.gz",
                  "38f62cc5d9f0409205b20ff8ff01d7cc36659993"),
]

# HDF5.h in /workspace/artifacts/805ccba77cd286c1afc127d1e45aae324b507973/include
# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-c

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export LDFLAGS_MAKE="${LDFLAGS}"
CONFIGURE_OPTIONS=""

if [[ ${target} == *-mingw* ]]; then
    export LIBS="-lhdf5-0 -lhdf5_hl-0 -lcurl-4 -lz"
    # linking fails with: "libtool:   error: can't build x86_64-w64-mingw32 shared library unless -no-undefined is specified"
    # unless -no-undefined is added to LDFLAGS
    LDFLAGS_MAKE="${LDFLAGS} ${LIBS} -no-undefined -Wl,--export-all-symbols"

    # additional configure options from
    # https://github.com/Unidata/netcdf-c/blob/5df5539576c5b2aa8f31d4b50c4f8258925589dd/.github/workflows/run_tests_win_mingw.yml#L38
    CONFIGURE_OPTIONS="--disable-byterange"
elif [[ "${target}" == *-apple-* ]]; then
    # this file is referenced by hdf.h by not installed
    touch ${includedir}/features.h
fi

if [[ ${target} -ne x86_64-linux-gnu ]]; then
    # utilities are necessary to run the tests
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --disable-utilities"
fi

# https://github.com/JuliaPackaging/Yggdrasil/issues/5031#issuecomment-1155000045
rm /workspace/destdir/lib/*.la

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --disable-static \
    --disable-dap-remote-tests \
    --disable-plugins \
    $CONFIGURE_OPTIONS

make LDFLAGS="${LDFLAGS_MAKE}" -j${nproc}

if [[ ${target} == x86_64-linux-gnu ]]; then
   make check
fi

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
    Platform("aarch64","macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libnetcdf", :libnetcdf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="HDF5_jll"), compat="~1.12.2"),
    Dependency("Zlib_jll"),
    Dependency("XML2_jll"),
    Dependency("LibCURL_jll"; compat = "7.73.0"),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")

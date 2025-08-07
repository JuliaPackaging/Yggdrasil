# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.

name = "NetCDF"
upstream_version = v"4.9.3"

# Offset to add to the version number.  Remember to always bump this.
version_offset = v"1.0.0"

version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build NetCDF
sources = [
    ArchiveSource("https://downloads.unidata.ucar.edu/netcdf-c/$(upstream_version)/netcdf-c-$(upstream_version).tar.gz",
                  "a474149844e6144566673facf097fea253dc843c37bc0a7d3de047dc8adda5dd"),
]

# HDF5.h in /workspace/artifacts/805ccba77cd286c1afc127d1e45aae324b507973/include
# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/netcdf-c*

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export LDFLAGS_MAKE="${LDFLAGS}"
CONFIGURE_OPTIONS=""

if [[ ${target} == *-mingw* ]]; then
    # we should determine the dll version (?) automatically
    export LIBS="-lcurl-4 -lz"
    # linking fails with: "libtool:   error: can't build x86_64-w64-mingw32 shared library unless -no-undefined is specified"
    # unless -no-undefined is added to LDFLAGS
    LDFLAGS_MAKE="${LDFLAGS} ${LIBS} -no-undefined -Wl,--export-all-symbols"
    # additional configure options from
    # https://github.com/Unidata/netcdf-c/blob/5df5539576c5b2aa8f31d4b50c4f8258925589dd/.github/workflows/run_tests_win_mingw.yml#L38
    CONFIGURE_OPTIONS="--disable-byterange"
fi

if [[ ${target} -ne x86_64-linux-gnu ]]; then
    # utilities are necessary to run the tests
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --disable-utilities"
fi

if [[ ${target} == x86_64-linux-musl ]]; then
    # see
    # https://github.com/JuliaPackaging/Yggdrasil/blob/48af117395188f48d361a46ea929ee7563d9c2e4/A/ADIOS2/build_tarballs.jl

    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
fi

if [[ ${target} == *-unknown-freebsd* ]]; then
    # MPI isn't autodetected; we need to specify the libraries
    case ${bb_full_target} in
        *mpich*)
            export LIBS="-lmpi -lm -lexecinfo -lutil -lz";;
        *mpitrampoline*)
            export LIBS="-lmpitrampoline -ldl";;
        *openmpi*)
            export LIBS="-lmpi -lm -lexecinfo -lutil -lz";;
    esac
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --disable-static \
    --disable-dap-remote-tests \
    --disable-plugins \
    ${CONFIGURE_OPTIONS}

make LDFLAGS="${LDFLAGS_MAKE}" -j${nproc}

if [[ ${target} == x86_64-linux-gnu ]]; then
   make check
fi

make install

nc-config --all
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    # NetCDF tools
    # ExecutableProduct("nc-config", :nc_config),
    ExecutableProduct("nc4print", :nc4print),
    ExecutableProduct("nccopy", :nccopy),
    ExecutableProduct("ncdump", :ncdump),
    ExecutableProduct("ncgen", :ncgen),
    ExecutableProduct("ncgen3", :ncgen3),
    ExecutableProduct("ocprint", :ocprint),

    # NetCDF library
    LibraryProduct("libnetcdf", :libnetcdf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Blosc_jll"; compat="1.21.6"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("libaec_jll"; compat="1.1.3"), # This is the successor of szlib
    Dependency("libzip_jll"; compat="1.11.3"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"5")

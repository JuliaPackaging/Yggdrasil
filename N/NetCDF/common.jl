# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

function configure(version_offset, min_julia_version)
    # The version of this JLL is decoupled from the upstream version.
    # Whenever we package a new upstream release, we initially map its
    # version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
    # So for example version 2.6.3 would become 200.600.300.

    name = "NetCDF"
    upstream_version = v"4.8.1"
    version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                            upstream_version.minor * 100 + version_offset.minor,
                            upstream_version.patch * 100 + version_offset.patch)

    # Collection of sources required to build NetCDF
    sources = [
        ArchiveSource("https://github.com/Unidata/netcdf-c/archive/v$(upstream_version).zip",
                      "e4e75523466de4187cff29784ff12755925f17e753bff0c9c46cd670ca63c6b2"),
        DirectorySource("../bundled"),
    ]

    # HDF5.h in /workspace/artifacts/805ccba77cd286c1afc127d1e45aae324b507973/include
    # Bash recipe for building across all platforms
    script = raw"""
cd $WORKSPACE/srcdir/netcdf-c-*

export CPPFLAGS="-I${includedir}"
export CFLAGS="-std=c99"
export LDFLAGS="-L${libdir}"
export LDFLAGS_MAKE="${LDFLAGS}"
CONFIGURE_OPTIONS=""

for p in ../patches/*.patch; do
    atomic_patch -p1 "${p}"
done

if [[ ${target} == *-mingw* ]]; then
    export LIBS="-lhdf5-0 -lhdf5_hl-0 -lcurl-4 -lz"
    # linking fails with: "libtool:   error: can't build x86_64-w64-mingw32 shared library unless -no-undefined is specified"
    # unless -no-undefined is added to LDFLAGS
    LDFLAGS_MAKE="${LDFLAGS} ${LIBS} -no-undefined -Wl,--export-all-symbols"

    # testset fails on mingw (NetCDF 4.8.1)
    # libtool: link: cc -fno-strict-aliasing -o .libs/pathcvt.exe pathcvt.o  -L/workspace/destdir/bin ../liblib/.libs/libnetcdf.dll.a -lhdf5-0 -lhdf5_hl-0 -lcurl-4 -lz -L/workspace/destdir/lib
    # pathcvt.o:pathcvt.c:(.text+0x15c): undefined reference to `NCpathcvt'
    CONFIGURE_OPTIONS="--disable-testsets"
elif [[ "${target}" == *-apple-* ]]; then
    # this file is referenced by hdf.h by not installed
    touch ${includedir}/features.h
fi

if [[ ${target} -ne x86_64-linux-gnu ]]; then
    # utilities are necessary to run the tests
    CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS --disable-utilities"
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --disable-static \
    --disable-dap-remote-tests \
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
        Platform("x86_64", "windows"),
        Platform("i686", "windows"),
    ]
    if min_julia_version == v"1.6"
        push!(platforms, Platform("aarch64","macos"))
    end
    # The products that we will ensure are always built
    products = [
        LibraryProduct("libnetcdf", :libnetcdf),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = [
        Dependency(PackageSpec(name="HDF5_jll"), compat="1.12.1"),
        Dependency("Zlib_jll"),
    ]

    jll_stdlibs = Dict(
        v"1.3" => [
            Dependency("LibCURL_jll", v"7.71.1"),
            # The following libraries are dependencies of LibCURL_jll which is now a
            # stdlib, but the stdlib doesn't explicitly list its dependencies
            Dependency("LibSSH2_jll", v"1.9.0"),
            Dependency("MbedTLS_jll", v"2.16.8"),
            Dependency("nghttp2_jll", v"1.40.0"),
        ],
        v"1.6" => [
            Dependency("LibCURL_jll"),
            # The following libraries are dependencies of LibCURL_jll which is now a
            # stdlib, but the stdlib doesn't explicitly list its dependencies
            Dependency("LibSSH2_jll"),
            Dependency("MbedTLS_jll", v"2.24.0"),
            Dependency("nghttp2_jll"),
        ]
    )

    append!(dependencies, jll_stdlibs[min_julia_version])

    # Build the tarballs, and possibly a `build.jl` as well.
    return name, version, sources, script, platforms, products, dependencies
end

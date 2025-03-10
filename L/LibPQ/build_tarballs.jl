# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibPQ"
version = v"16.8"
tzcode_version = "2025a"

# Collection of sources required to build LibPQ
sources = [
    GitSource(
        "https://github.com/postgres/postgres.git",
        "71eb35c0b18de96537bd3876ec9bf8075bfd484f",
    ),
    ArchiveSource(
        "https://data.iana.org/time-zones/releases/tzcode$tzcode_version.tar.gz",
        "119679d59f76481eb5e03d3d2a47d7870d592f3999549af189dbd31f2ebf5061",
        unpack_target="zic-build",
    ),
]

# Bash recipe for building across all platforms
# NOTE: readline and zlib are not used by libpq
script = raw"""
cd zic-build
make CC=$BUILD_CC VERSION_DEPS= zic
mv zic ../ && cd ../ && rm -rf zic-build
export ZIC=$WORKSPACE/srcdir/zic
export PATH=$WORKSPACE/srcdir:$PATH
# We need `__STDC_WANT_LIB_EXT1__` for `memset_s` on macOS
export CFLAGS="-std=c11 -D__STDC_WANT_LIB_EXT1__"

cd postgres

if [[ ${target} == *-apple-* ]]; then
    ./configure --prefix=${prefix} \
        --build=${MACHTYPE} \
        --host=${target} \
        --with-includes=${includedir} \
        --with-libraries=${libdir} \
        --without-readline \
        --without-zlib \
        --with-ssl=openssl \
        "${FLAGS[@]}"

    make -C src/interfaces/libpq -j${nproc}
    make -C src/interfaces/libpq install
    make -C src/include install

else
    meson setup meson_build --prefix=$prefix \
        --cross-file="${MESON_TARGET_TOOLCHAIN}" \
        --bindir=${bindir} \
        --libdir=${libdir} \
        --includedir=${includedir} \
        -Dssl=openssl \
        -Dzlib=disabled \
        -Dreadline=disabled \
        -Dtap_tests=disabled \
        -Dplpython=disabled \
        -Dplperl=disabled \
        -Dnls=disabled

    cd meson_build
    ninja -j${nproc}
    ninja install
    cd ../

    if [[ ${target} == *-w64-mingw32 ]]; then
        mv -v meson_build/src/interfaces/libpq/* ${prefix}/lib
    fi    
fi


# Delete static library
rm ${prefix}/lib/libpq.a
install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpq", :LIBPQ_HANDLE)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Bison_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Kerberos_krb5_jll"; compat="1.21.3", platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
    Dependency("ICU_jll"; compat="76.1"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

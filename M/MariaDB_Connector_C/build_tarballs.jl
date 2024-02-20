# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MariaDB_Connector_C"
version = v"3.3.2"
julia_compat = "1.6"

# Collection of sources required to build MariaDB_Connector_C
sources = [
    GitSource("https://github.com/mariadb-corporation/mariadb-connector-c.git",
              "1bd8c8bf39c259a1b1713974684e24d168a09d13"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mariadb-*/

if [[ "${target}" == *-mingw* ]]; then
    for p in ../patches/*.patch; do
        atomic_patch -p1 "${p}"
    done
    export CFLAGS="-std=c99"
    # Minimum version of Windows supported by MariaDB is 7,
    # see tables in https://docs.microsoft.com/en-us/windows/win32/winprog/using-the-windows-headers
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="${CFLAGS} -D_WIN32_WINNT=0x0601"
    elif [[ "${nbits}" == 64 ]]; then
        export CFLAGS="${CFLAGS} -DNTDDI_VERSION=0x06010000"
    fi
elif [[ "${target}" == *-apple-* ]]; then
    # Nuke header files in the sysroot
    # to avoid they'll be picked up by CMake
    rm -rf /opt/${target}/${target}/sys-root/usr/include/openssl
    rm -rf /opt/${target}/${target}/sys-root/usr/include/{iconv.h,libcharset.h,localcharset.h}

    SYMBS_DEFS=()
    for sym in iconv iconv_close iconv_open; do
        SYMBS_DEFS+=(-D${sym}=lib${sym})
    done
    export CFLAGS="${SYMBS_DEFS[@]}"
fi

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_MYSQLCOMPAT=OFF \
    -DWITH_EXTERNAL_ZLIB=ON \
    -DZLIB_FOUND=ON \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -DOPENSSL_FOUND=ON \
    -DOPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext} \
    -DOPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext} \
    -DICONV_LIBRARIES=${libdir}/libiconv.${dlext} \
    -DICONV_INCLUDE_DIR=${includedir}
make -j${nproc}
make install
install_license ../COPYING.LIB
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmariadb", :libmariadb, ["lib/mariadb"]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    Dependency("Libiconv_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat)

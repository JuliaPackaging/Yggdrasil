# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MariaDB_Connector_C"
version = v"3.3.9"
julia_compat = "1.6"

# Collection of sources required to build MariaDB_Connector_C
sources = [
    GitSource("https://github.com/mariadb-corporation/mariadb-connector-c.git",
              "e714a674827fbb8373dd71da634dd04736d7b5a6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mariadb-*/

# https://github.com/mariadb-corporation/mariadb-connector-c/pull/244
atomic_patch -p1 ../patches/sys-poll.patch
# There are warnings on 32-bit systems, but they hardcode `-Werror`.  Also, issues are closed, so we can't even report it.
atomic_patch -p1 ../patches/no-werror.patch

if [[ "${target}" == *-mingw* ]]; then
    for p in ../patches/{0004-Add-ws2_32-to-remoteio-libraries,001-mingw-build,002-fix-prototype,003-gcc-fix-use_VA_ARGS,005-Add-definition-of-macros-and-structs-missing-in-MinG,fix-undefined-sec-e-invalid-parameter}.patch; do
        atomic_patch -p1 "${p}"
    done
    export CFLAGS="-std=c99"
    # Minimum version of Windows supported by MariaDB is 7,
    # see tables in https://docs.microsoft.com/en-us/windows/win32/winprog/using-the-windows-headers
    if [[ "${nbits}" == 64 ]]; then
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

if [[ "${target}" == x86_64-linux-* ]] || [[ "${target}" == x86_64-*-mingw* ]]; then
   # You can avoid this in the future when targeting OpenSSL_jll@v3.0.13+.
   OPENSSL_CRYPTO_LIBRARY=${libdir}64/libcrypto.${dlext}
   OPENSSL_SSL_LIBRARY=${libdir}64/libssl.${dlext}
else
   OPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext}
   OPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext}
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
    -DOPENSSL_CRYPTO_LIBRARY="${OPENSSL_CRYPTO_LIBRARY}" \
    -DOPENSSL_SSL_LIBRARY="${OPENSSL_SSL_LIBRARY}"
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
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat)

# Build trigger: 1

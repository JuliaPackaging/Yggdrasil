# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MariaDB_Connector_C"
version = v"3.4.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://archive.mariadb.org/connector-c-$(version)/mariadb-connector-c-$(version)-src.tar.gz",
                  "156aed3b49f857d0ac74fb76f1982968bcbfd8382da3f5b6ae71f616729920d7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mariadb-*/

# There are warnings on 32-bit systems, but they hardcode `-Werror`.  Also, issues are closed, so we can't even report it.
atomic_patch -p1 ../patches/no-werror.patch

# GCC 14+ has stricter type checking that causes errors with MariaDB 3.4
# See https://gcc.gnu.org/gcc-14/porting_to.html
# -Wno-error: disable all warnings-as-errors
# -Wno-incompatible-pointer-types: needed for some platforms (e.g., riscv64)
# Both flags require GCC 6+ (ensured by preferred_gcc_version below)
export CFLAGS="${CFLAGS} -Wno-error -Wno-incompatible-pointer-types"

if [[ "${target}" == *-mingw* ]]; then
    for p in ../patches/{0004-Add-ws2_32-to-remoteio-libraries,001-mingw-build,002-fix-prototype,003-gcc-fix-use_VA_ARGS,005-Add-definition-of-macros-and-structs-missing-in-MinG,fix-undefined-sec-e-invalid-parameter}.patch; do
        atomic_patch -p1 "${p}"
    done
    export CFLAGS="${CFLAGS} -std=c99"
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
    export CFLAGS="${CFLAGS} ${SYMBS_DEFS[@]}"
fi

# OpenSSL 3.0.13+ installs libraries in lib (not lib64)
OPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext}
OPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext}

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_COMPILE_WARNING_AS_ERROR=OFF \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
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

# Filter out riscv64 due to build failures (unknown cause - no access to logs)
# TODO: Re-enable once we can diagnose and fix the riscv64 build issue
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmariadb", :libmariadb, ["lib/mariadb"]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    Dependency("Libiconv_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")

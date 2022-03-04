# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MariaDB_Connector_ODBC"
version = v"3.1.7"

# Collection of sources required to build MariaDB_Connector_ODBC
sources = [
    ArchiveSource("https://downloads.mariadb.com/Connectors/odbc/connector-odbc-3.1.7/mariadb-connector-odbc-3.1.7-ga-src.tar.gz",
                  "699c575e169d770ccfae1c1e776aa7725d849046476bf6579d292c89e8c8593e"),
    FileSource("https://downloads.mariadb.com/Connectors/odbc/connector-odbc-3.1.7/mariadb-connector-odbc-3.1.7-win64.msi",
               "ef1ad796cc4aba67aa6606b35239302c579b7894604239d1caaa1f2d10623bd2"; filename = "x86_64-w64-mingw32.msi"),
    FileSource("https://downloads.mariadb.com/Connectors/odbc/connector-odbc-3.1.7/mariadb-connector-odbc-3.1.7-win32.msi",
               "a60b74dc3af0b450d892731c2973037beef6fc972e0813f3db9f28f083a63402"; filename = "i686-w64-mingw32.msi"),
    ## Keep the patches just in case some day we decide to build for Windows
    ## from source
    # DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
install_license $WORKSPACE/srcdir/mariadb-connector*/COPYING

if [[ "${target}" == *-mingw* ]]; then
    # For Windows just use the prebuilt library
    mkdir -p "${libdir}"
    cd $WORKSPACE/srcdir
    apk add p7zip
    7z x "${target}.msi"
    cp mariadb_odbc_dll "${libdir}/mariadb_odbc.dll"
    exit
fi

cd $WORKSPACE/srcdir/mariadb-connector*/

# Skip building of macOS package
sed -i 's/ADD_SUBDIRECTORY(osxinstall)/# ADD_SUBDIRECTORY(osxinstall)/' CMakeLists.txt

## Keep this for reference in case we decide to build for Windows from source
# if [[ "${target}" == *-mingw* ]]; then
#     # Disable dialog plugin
#     sed -i 's/-DPLUGINS_LIB_DIR.*:dialog.*//' CMakeLists.txt
#     atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-fix-case-headers-windows.patch"
#     # The following is not really a patch: Microsoft Visual C++ thinks that it's
#     # a good idea to put some stray characters in the first bits of the file,
#     # making it hard to digest for MinGW.  We can't diff the file as the
#     # original one appears to be binary, because of the stray character.
#     cp "${WORKSPACE}/srcdir/patches/resource.h" dsn/
# fi

mkdir build && cd build

export CFLAGS="-I${includedir}/mariadb"
# Find the MariaDB lib and link to the right OpenSSL and Zlib libraries
export LDFLAGS="-L${libdir}/mariadb ${libdir}/libssl.${dlext} ${libdir}/libcrypto.${dlext} -lz"
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_OPENSSL=ON \
    -DWITH_SSL=OPENSSL \
    -DOPENSSL_FOUND=ON \
    -DOPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext} \
    -DOPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext} \
    -DICONV_LIBRARIES=${libdir}/libiconv.${dlext} \
    -DICONV_INCLUDE_DIR=${includedir} \
    ..
make -j${nproc}
make install
"""

platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="glibc"),
    # Platform("armv7l", "linux"; libc="glibc"),
    # Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    # Platform("aarch64", "linux"; libc="musl"),
    # Platform("armv7l", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    # Platform("x86_64", "freebsd"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmaodbc", "mariadb_odbc"], :libmaodbc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("MariaDB_Connector_C_jll"),
    Dependency("iODBC_jll"),
    Dependency("Libiconv_jll"),
    Dependency("unixODBC_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MariaDB_Connector_ODBC"
version = v"3.1.16"

# Collection of sources required to build MariaDB_Connector_ODBC
sources = [
    ArchiveSource("https://downloads.mariadb.com/Connectors/odbc/connector-odbc-$(version)/mariadb-connector-odbc-$(version)-src.tar.gz",
                  "4fd0de9d0e9da883ac9801cbf97953be9cc9010830417c44e8b339deca48463d"),
    DirectorySource("./bundled"),
    FileSource("https://downloads.mariadb.com/Connectors/odbc/connector-odbc-$(version)/mariadb-connector-odbc-$(version)-win64.msi",
               "9d027383b88b7f82203081402242828cf3b54cdd9d1ea7a60be145e9a3dd750e"; filename = "x86_64-w64-mingw32.msi"),
    FileSource("https://downloads.mariadb.com/Connectors/odbc/connector-odbc-$(version)/mariadb-connector-odbc-$(version)-win32.msi",
               "341bb7126cc40314244dd62a5c77799d2f9429ac5142880320f3bbc3fd8dc4ee"; filename = "i686-w64-mingw32.msi"),
    ## Keep the patches just in case some day we decide to build for Windows
    ## from source
    # DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
install_license $WORKSPACE/srcdir/mariadb-connector*/COPYING

if [[ "${target}" == *-mingw* ]]; then
    # For Windows just use the prebuilt library
    cd $WORKSPACE/srcdir
    apk add p7zip
    7z x "${target}.msi"
    install -Dvm 755 mariadb_odbc_dll "${libdir}/mariadb/mariadb_odbc.dll"
    exit
fi

cd $WORKSPACE/srcdir/mariadb-connector*/

# Skip building of macOS package
sed -i 's/ADD_SUBDIRECTORY(osxinstall)/# ADD_SUBDIRECTORY(osxinstall)/' CMakeLists.txt

# They want to run a script which changes the name of the required library
# `libiodbcinst` from `libiodbcinst.2.dylib` to `libiodbcinst.dylib` which has the only
# effect of making `libmaodbc` not loadable, as `libiodbcinst` is dlopened as... guess
# what... `libiodbcinst.2.dylib`.
atomic_patch -p1 ../patches/do-not-change-name-of-iodbcinst.patch

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
    Platform("aarch64", "macos"),
    # Platform("x86_64", "freebsd"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmaodbc", "mariadb_odbc"], :libmaodbc,
                   raw"${libdir}/mariadb"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MariaDB_Connector_C_jll"),
    Dependency("iODBC_jll"),
    Dependency("Libiconv_jll"),
    Dependency("unixODBC_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

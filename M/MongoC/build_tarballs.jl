# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MongoC"
version = v"1.16.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mongodb/mongo-c-driver/releases/download/1.16.2/mongo-c-driver-1.16.2.tar.gz", "0a722180e5b5c86c415b9256d753b2d5552901dc5d95c9f022072c3cd336887e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mongo-c-driver-1.16.2/
sed -i "s/Windows.h/windows.h/" src/libmongoc/src/mongoc/mongoc-client.c
sed -i "s/WinDNS.h/windns.h/" src/libmongoc/src/mongoc/mongoc-client.c
sed -i "s/Mstcpip.h/mstcpip.h/" src/libmongoc/src/mongoc/mongoc-client.c
sed -i "s/Mstcpip.h/mstcpip.h/" src/libmongoc/src/mongoc/mongoc-socket.c
sed -i "s/Dnsapi/dnsapi/" build/cmake/FindResSearch.cmake
mkdir cmake-build
cd cmake-build/

if [[ "${nbits}" == 32 ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
elif [[ "${target}" != *-apple-* ]]; then 
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

cmake  -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_SSL=OPENSSL -DENABLE_SASL=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTS=OFF -DENABLE_UNINSTALL=OFF -DENABLE_STATIC=OFF -DENABLE_SNAPPY=ON -DENABLE_MONGOC=ON -DENABLE_BSON=ON -DOPENSSL_ROOT_DIR=$prefix -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} ..
make -j${nproc}
make install

if [[ "${target}" == *-apple-darwin* ]]; then
    rm ${libdir}/libbson-1.0.0.dylib
    rm ${libdir}/libmongoc-1.0.0.dylib
    mv ${libdir}/libmongoc-1.0.0.0.0.dylib ${libdir}/libmongoc-1.0.0.dylib
    mv ${libdir}/libbson-1.0.0.0.0.dylib ${libdir}/libbson-1.0.0.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libbson-1", "libbson-1.0", "libbson"], :libbson),
    LibraryProduct(["libmongoc-1", "libmongoc-1.0", "libmongoc"], :libmongoc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
    Dependency(PackageSpec(name="snappy_jll", uuid="fe1e1685-f7be-5f59-ac9f-4ca204017dfd"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

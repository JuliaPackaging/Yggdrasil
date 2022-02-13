# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Thrift"
version = v"0.13.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://mirror.23media.de/apache/thrift/0.13.0/thrift-0.13.0.tar.gz", "7ad348b88033af46ce49148097afe354d513c1fca7c607b59c33ebb6064b5179"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd thrift-*/

sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/windows/config.h
sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/windows/SocketPair.h
sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/windows/WinFcntl.h
sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/windows/TWinsockSingleton.h
sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/windows/GetTimeOfDay.cpp
sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/transport/PlatformSocket.h
sed -i 's/Winsock2/winsock2/g' lib/cpp/src/thrift/protocol/TProtocol.h
sed -i 's/WinSock2/winsock2/g' lib/cpp/test/OpenSSLManualInitTest.cpp
sed -i 's/Shlwapi/shlwapi/g' lib/cpp/src/thrift/transport/THttpServer.cpp
sed -i 's/Windows.h/windows.h/g' lib/cpp/src/thrift/windows/Sync.h
sed -i 's/Windows.h/windows.h/g' lib/cpp/src/thrift/windows/OverlappedSubmissionThread.h
sed -i 's/AccCtrl.h/accctrl.h/g' lib/cpp/src/thrift/transport/TPipeServer.cpp
sed -i 's/Aclapi.h/aclapi.h/g' lib/cpp/src/thrift/transport/TPipeServer.cpp
sed -i 's/WS2tcpip.h/ws2tcpip.h/g' lib/cpp/src/thrift/windows/SocketPair.cpp

if [[ "${target}" == *86*-linux-musl* ]]; then
    pushd /opt/${target}/lib/gcc/${target}/*/include
    # Fix bug in Musl C library, see
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387
    atomic_patch -p0 $WORKSPACE/srcdir/patches/mm_malloc.patch
    popd
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-boost="${prefix}" \
    --without-py3 \
    --without-python \
    --enable-tests=no \
    --enable-tutorial=no \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes
make -j${nproc}
make install


if [[ "${target}" == *-mingw* ]]; then
    # Manually build the shared library for Windows
    cd "${prefix}/lib"
    cc -shared -o "${libdir}/libthrift.${dlext}" libthrift.a
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libthrift", :libthrift),
    ExecutableProduct("thrift", :thrift)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

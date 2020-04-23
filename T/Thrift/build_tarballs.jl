# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Thrift"
version = v"0.13.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://mirror.23media.de/apache/thrift/0.13.0/thrift-0.13.0.tar.gz", "7ad348b88033af46ce49148097afe354d513c1fca7c607b59c33ebb6064b5179")
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

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-boost="${prefix}" --without-py3 --without-python ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes --enable-tests=no --enable-tutorials=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]


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

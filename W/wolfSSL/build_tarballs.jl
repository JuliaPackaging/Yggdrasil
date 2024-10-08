# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wolfSSL"
version = v"5.7.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wolfSSL/wolfssl.git", "00e42151ca061463ba6a95adb2290f678cbca472"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
                  "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wolfssl*

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DWOLFSSL_EXAMPLES=no \
-DWOLFSSL_CRYPT_TESTS=no \
-DBUILD_SHARED_LIBS=ON

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude = x -> Sys.iswindows(x))


# The products that we will ensure are always built
products = [
    LibraryProduct("libwolfssl", :libwolfssl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdatachannel"
version = v"0.20.2"
# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/paullouisageneau/libdatachannel.git", "9cbe6a2a1f21cde901bca9571581a96c6cda03cf"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz", 
               "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f")
]

# Bash recipe for building across all platforms
script = raw"""
if [[ ${target} == x86_64*mingw* ]]; then
    export OPENSSL_ROOT_DIR="${prefix}/lib64"
fi

if [[ ${target} == *musl* ]]; then
mkdir -p ${prefix}/include/sys
touch ${prefix}/include/sys/random.h
cat >> ${prefix}/include/sys/random.h <<EOF
#define _XOPEN_SOURCE 700
#include <sys/types.h>
#include <sys/syscall.h>
#define getrandom(buf, sz, flags) syscall(SYS_getrandom, buf, sz, flags)

EOF

fi

if [[ "${bb_full_target}" == x86_64-apple-darwin* ]]; then
    # LLVM 15+ requires macOS SDK 10.14.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

cd $WORKSPACE/srcdir/libdatachannel
git submodule update --init --recursive --depth 1
cmake -B build \
    -DUSE_GNUTLS=0 \
    -DUSE_NICE=0 \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license $WORKSPACE/srcdir/libdatachannel/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libdatachannel", :libdatachannel)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
    # Links to libgcc_s on linux for something
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p),  platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.2.0")

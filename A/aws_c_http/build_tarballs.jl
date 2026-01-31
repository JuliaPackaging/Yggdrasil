# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_c_http"
version = v"0.10.10"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-c-http.git", "a9745ea9998f679cd7456e7d23cc8820e38c97d4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-c-http

# Build 1: Vanilla upstream version
mkdir build-vanilla && cd build-vanilla
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
cmake --build . -j${nproc} --target install
cd ..

# Save vanilla library before patching
cp -v ${libdir}/libaws-c-http.${dlext} /tmp/libaws-c-http-vanilla.${dlext}

# Apply server-side websocket upgrade patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-Add-support-for-server-side-websocket-upgrade.patch

# Build 2: Patched version with server-side websocket support
mkdir build-patched && cd build-patched
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ..
cmake --build . -j${nproc} --target install
cd ..

# Rename patched library and restore vanilla
mv -v ${libdir}/libaws-c-http.${dlext} ${libdir}/libaws-c-http-jq.${dlext}
mv -v /tmp/libaws-c-http-vanilla.${dlext} ${libdir}/libaws-c-http.${dlext}
"""

platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
# - libaws_c_http: vanilla upstream library
# - libaws_c_http_jq: patched version with server-side websocket upgrade support
products = [
    LibraryProduct("libaws-c-http", :libaws_c_http),
    LibraryProduct("libaws-c-http-jq", :libaws_c_http_jq),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("aws_c_compression_jll"; compat="0.3.2"),
    Dependency("aws_c_io_jll"; compat="0.26.1"),
    BuildDependency("aws_lc_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")

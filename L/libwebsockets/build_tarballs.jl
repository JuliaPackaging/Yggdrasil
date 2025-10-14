# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "quickfix"
version = v"1.16.0"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/quickfix/quickfix.git", "92c85ca63fc260d16e24e0ece419ecdec9ffe868"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
    "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    DirectorySource("./bundled")
]

include("../../L/libjulia/common.jl")
julia_versions = [v"1.8", v"1.9", v"1.10", v"1.11"]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/quickfix

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `shared_timed_mutex` and `std::filesystem`
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.15
    popd
fi

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

mkdir build && cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHAVE_SSL=ON \
    -DHAVE_GETTIMEOFDAY=ON \
    -DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS" \
    ..

make -j${nproc} install

install_license ${WORKSPACE}/srcdir/quickfix/LICENSE
"""

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = filter(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libquickfix", :libquickfix),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8", preferred_gcc_version=v"9")

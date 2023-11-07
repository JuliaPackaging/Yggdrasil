# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Blosc2"
version = v"2.11.2"

# Collection of sources required to build Blosc2
sources = [
    GitSource("https://github.com/Blosc/c-blosc2.git", "3ea8b4ae21563bc740c91f5abfe823c9b8438738"),
    # ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
    #               "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    # ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.0.sdk.tar.xz",
    #               "d3feee3ef9c6016b526e1901013f264467bb927865a03422a9cb925991cc9783"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc2/

rm -f /usr/share/cmake/Modules/Compiler/._*

# if [[ "${target}" == x86_64-apple-darwin* ]]; then
#     # export MACOSX_DEPLOYMENT_TARGET=10.15
#     # pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
#     export MACOSX_DEPLOYMENT_TARGET=11.0
#     pushd ${WORKSPACE}/srcdir/MacOSX11.*.sdk
#     rm -rf /opt/${target}/${target}/sys-root/System
#     cp -a usr/* "/opt/${target}/${target}/sys-root/usr/"
#     cp -a System "/opt/${target}/${target}/sys-root/"
#     popd
# fi

# Blosc2 mis-detects whether the system headers provide `_xsetbv`
# (probably on several platforms), and on `x86_64-w64-mingw32` the
# functions have incompatible return types (although both are 64-bit
# integers).
atomic_patch -p1 ../patches/_xsetbv.patch

# # fix compile arguments for armv7l <https://github.com/Blosc/c-blosc2/pull/563>
# atomic_patch -p1 ../patches/armv7l.patch

#    -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="" \

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_STATIC=OFF \
    -DPREFER_EXTERNAL_ZLIB=ON \
    -DPREFER_EXTERNAL_ZSTD=ON \
    -DPREFER_EXTERNAL_LZ4=ON \
    ..
make -j${nproc}
make install
install_license ../LICENSES/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc2", :libblosc2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.0"),
    Dependency("Lz4_jll"; compat="1.9.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 8 for powerpc.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")

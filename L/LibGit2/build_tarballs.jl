using BinaryBuilder

name = "LibGit2"
version = v"1.4.3"

# Collection of sources required to build libgit2
sources = [
    GitSource("https://github.com/libgit2/libgit2.git",
              "465bbf88ea939a965fbcbade72870c61f815e457"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgit2*/

atomic_patch -p1 $WORKSPACE/srcdir/patches/libgit2-agent-nonfatal.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/libgit2-hostkey.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/libgit2-win32-ownership.patch

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DUSE_THREADS=ON
    -DUSE_BUNDLED_ZLIB=ON
    -DUSE_SSH=ON
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
)

# Special windows flags
if [[ ${target} == *-mingw* ]]; then
    BUILD_FLAGS+=(-DWIN32=ON -DMINGW=ON -DBUILD_CLAR=OFF)
    if [[ ${target} == i686-* ]]; then
        BUILD_FLAGS+=(-DCMAKE_C_FLAGS="-mincoming-stack-boundary=2")
    fi

    # For some reason, CMake fails to find libssh2 using pkg-config.
    BUILD_FLAGS+=(-Dssh2_RESOLVED=${bindir}/libssh2.dll)
elif [[ ${target} == *linux* ]] || [[ ${target} == *freebsd* ]]; then
    # If we're on Linux or FreeBSD, explicitly ask for mbedTLS instead of OpenSSL
    BUILD_FLAGS+=(-DUSE_HTTPS=mbedTLS -DUSE_SHA1=CollisionDetection -DCMAKE_INSTALL_RPATH="\$ORIGIN")
fi

mkdir build && cd build

cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgit2", :libgit2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MbedTLS_jll"; compat="~2.28.0"),
    Dependency("LibSSH2_jll"; compat="1.10.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")

using BinaryBuilder

name = "LibGit2"
version = v"0.27.7"

# Collection of sources required to build Ogg
sources = [
   "https://github.com/libgit2/libgit2.git" =>
   "f23dc5b29f1394928a940d7ec447f4bfd53dad1f",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgit2*/

BUILD_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DTHREADSAFE=ON
    -DUSE_BUNDLED_ZLIB=ON
    "-DCURL_INCLUDE_DIRS=
    "-DCMAKE_INSTALL_PREFIX=${prefix}"
    "-DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain"
)

# Special windows flags
if [[ ${target} == *-mingw* ]]; then
    BUILD_FLAGS+=(-DWIN32=ON -DMINGW=ON -DBUILD_CLAR=OFF)
    if [[ ${target} == i686-* ]]; then
        BUILD_FLAGS+=(-DCMAKE_C_FLAGS="-mincoming-stack-boundary=2")
    fi
fi


mkdir build
cd build

cmake .. "${BUILD_FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = prefix -> [
    LibraryProduct(prefix, "libssh2", :libssh2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.16.0/build_MbedTLS.v2.13.1.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/LibSSH2-v1.8.0-0/build_LibSSH2.v1.8.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

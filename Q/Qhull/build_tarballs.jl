# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qhull"
version = v"2019.1"

# Collection of sources required to build FFMPEG
sources = [
    "https://github.com/qhull/qhull/archive/$(version.major).$(version.minor).tar.gz" =>
    "b684fb43244a5c4caae652af9022ed5d85ce15210835bce054a33fb26033a1a5",
]

# Bash recipe for building across all platforms
# TODO: Theora once it's available
script = raw"""
# initial setup
cd $WORKSPACE/srcdir
cd Qhull/
apk add coreutils yasm

if [[ "${target}" == *-linux-* ]]; then
    export ccOS="linux"
elif [[ "${target}" == *-apple-* ]]; then
    export ccOS="darwin"
elif [[ "${target}" == *-w32-* ]]; then
    export ccOS="mingw32"
elif [[ "${target}" == *-w64-* ]]; then
    export ccOS="mingw64"
elif [[ "${target}" == *-unknown-freebsd* ]]; then
    export ccOS="freebsd"
else
    export ccOS="linux"
fi

if [[ "${target}" == x86_64-* ]]; then
    export ccARCH="x86_64"
elif [[ "${target}" == i686-* ]]; then
    export ccARCH="i686"
elif [[ "${target}" == arm-* ]]; then
    export ccARCH="arm"
elif [[ "${target}" == aarch64-* ]]; then
    export ccARCH="aarch64"
elif [[ "${target}" == powerpc64le-* ]]; then
    export ccARCH="powerpc64le"
else
    export ccARCH="x86_64"
fi

pkg-config --list-all

# begin the build process

cd build
# Generate makefiles
cmake -G "Unix Makefiles" .. && cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
# Ensure the config is correct
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
# Run the build script
make
# Install Qhull
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("qhull", :qhull),
    ExecutableProduct("rbox", :rbox),
    ExecutableProduct("qconvex", :qconvex),
    ExecutableProduct("qdelaunay", :qdelaunay),
    ExecutableProduct("qvoronoi", :qvoronoi),
    ExecutableProduct("qhalf", :qhalf),
    LibraryProduct()
]

# Dependencies that must be installed before this package can be built
# TODO: Theora once it's available
dependencies = [
    "libass_jll",
    "libfdk_aac_jll",
    "FriBidi_jll",
    "FreeType2_jll",
    "LAME_jll",
    "libvorbis_jll",
    "Ogg_jll",
    "LibVPX_jll",
    "x264_jll",
    "x265_jll",
    "Bzip2_jll",
    "Zlib_jll",
    "OpenSSL_jll",
    "Opus_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")

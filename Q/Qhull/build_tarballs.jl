# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Qhull"
version = v"2019.1"

# Collection of sources required to build FFMPEG
sources = [
    "https://github.com/qhull/qhull/archive/$(version.major).$(version.minor).tar.gz" =>
    "cf7235b76244595a86b9407b906e3259502b744528318f2178155e5899d6cf9f",
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
make -j${nproc}
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
    LibraryProduct(["libqhullstatic", "qhullstatic"], :libqhullstatic),
    LibraryProduct(["libqhullcpp", "qhullcpp"], :libqhullcpp),
    LibraryProduct(["liblibqhull_r", "qhull_r"], :libqhull_r),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SFML"
version = v"2.5.1"

# Collection of sources required to build SFML
sources = [
    GitSource(
        "https://github.com/SFML/SFML.git",
        "2f11710abc5aa478503a7ff3f9e654bd2078ebab",
    ),
    ArchiveSource(
        "https://www.sfml-dev.org/files/SFML-2.5.1-linux-gcc-64-bit.tar.gz",
        "34ad106e4592d2ec03245db5e8ad8fbf85c256d6ef9e337e8cf5c4345dc583dd",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
# build SFML
cd ${WORKSPACE}/srcdir

if [[ "${target}" == *linux* ]]; then

cd SFML-2.5.1/
mv ./include $WORKSPACE/destdir/
mv ./lib64 $WORKSPACE/destdir/
install_license ./share/SFML/license.md

else

cd SFML
mkdir build && cd build

CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"

if [[ "${target}" == *apple* ]]; then
CMAKE_FLAGS="${CMAKE_FLAGS} -DSFML_DEPENDENCIES_INSTALL_PREFIX=${WORKSPACE}/destdir/Frameworks"
fi

if [[ "${target}" == *mingw* ]] && [[ ${nbits} == 64 ]]; then
CMAKE_FLAGS="${CMAKE_FLAGS} -DOPENAL_LIBRARY=${WORKSPACE}/srcdir/SFML/extlibs/bin/x64/openal32.dll"
fi

if [[ "${target}" == *mingw* ]] && [[ ${nbits} == 32 ]]; then
CMAKE_FLAGS="${CMAKE_FLAGS} -DOPENAL_LIBRARY=${WORKSPACE}/srcdir/SFML/extlibs/bin/x86/openal32.dll"
fi

cmake .. ${CMAKE_FLAGS}
make
make install
install_license ../license.md 

fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsfml-window", "sfml-window"], :libsfml_window),
    LibraryProduct(["libsfml-audio", "sfml-audio"], :libsfml_audio),
    LibraryProduct(["libsfml-network", "sfml-network"], :libsfml_network),
    LibraryProduct(["libsfml-system", "sfml-system"], :libsfml_system),
    LibraryProduct(["libsfml-graphics", "sfml-graphics"], :libsfml_graphics),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
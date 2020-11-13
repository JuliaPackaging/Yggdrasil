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
    )
]

# Bash recipe for building across all platforms
script = raw"""
# build SFML
cd ${WORKSPACE}/srcdir

if [[ "${target}" == *linux* ]]; then

cd SFML-2.5.1/
mkdir -p ${prefix}
cp -r ./include/* ${prefix}/include
cp -r ./lib/* ${prefix}/lib
install_license ./share/SFML/license.md

else

cd SFML
mkdir build && cd build

CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release"

# if [[ "${target}" == *-linux-* ]]; then
#     apk add eudev-dev
# fi

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
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows")
]
platforms = expand_cxxstring_abis(platforms; skip=!Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsfml-window", "sfml-window"], :libsfml_window),
    LibraryProduct(["libsfml-audio", "sfml-audio"], :libsfml_audio),
    LibraryProduct(["libsfml-network", "sfml-network"], :libsfml_network),
    LibraryProduct(["libsfml-system", "sfml-system"], :libsfml_system),
    LibraryProduct(["libsfml-graphics", "sfml-graphics"], :libsfml_graphics)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libglvnd_jll"),
    Dependency("Ogg_jll"),
    Dependency("FLAC_jll"),
    Dependency("FreeType2_jll"),
    Dependency("libvorbis_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("OpenAL_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

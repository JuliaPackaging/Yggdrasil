# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libportaudio"
version = v"19.6.0"

# Collection of sources required to build libportaudio. Not all of these
# are used for all platforms.
sources = [
    FileSource("http://portaudio.com/archives/pa_stable_v190600_20161030.tgz",
               "f5a21d7dcd6ee84397446fa1fa1a0675bb2e8a4a6dceb4305a8404698d8d1513"),

    # This includes a patch
    DirectorySource("./bundled"),

    # uncomment the following lines to include ASIO support. To distribute the
    # resulting binaries you'll need to sign the licence agreement included with
    # the SDK at: https://www.steinberg.net/en/company/developers.html

    # FileSource("http://www.steinberg.net/sdk_downloads/ASIOSDK2.3.1.zip",
    #            "31074764475059448a9b7a56f103f4723ed60465e0e9d1a9446ca03dcf840f04")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# move the ASIO SDK to where CMake can find it
if [ -d "asiosdk2.3.1" ]; then
    mv "asiosdk2.3.1 svnrev312937/ASIOSDK2.3.1" asiosdk2.3.1
fi

# apply the patch
patch -dportaudio -p1 < portaudio_alsa_epipe_v3.diff

# First, build libportaudio
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON \
    -DCMAKE_PREFIX_PATH=${WORKSPACE}/destdir \
    ../portaudio/
make
make install
install_license "${WORKSPACE}/srcdir/portaudio/LICENSE.txt"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libportaudio", :libportaudio),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Build against `ALSA` on Linux
    Dependency("alsa_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

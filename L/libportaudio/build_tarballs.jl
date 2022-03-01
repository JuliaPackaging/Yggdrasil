# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libportaudio"
version = v"19.7.0"

# Collection of sources required to build libportaudio. Not all of these
# are used for all platforms.
sources = [
    ArchiveSource("http://files.portaudio.com/archives/pa_stable_v190700_20210406.tgz", 
                  "47efbf42c77c19a05d22e627d42873e991ec0c1357219c0d74ce6a2948cb2def"),

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
cd $WORKSPACE/srcdir/portaudio

# move the ASIO SDK to where CMake can find it
if [ -d "asiosdk2.3.1" ]; then
    mv "asiosdk2.3.1 svnrev312937/ASIOSDK2.3.1" asiosdk2.3.1
fi

# apply the patch
atomic_patch -p1 ../patches/win_ds_fix_warning.patch
atomic_patch -p1 ../patches/wasapi-32-bit-windows.patch

# First, build libportaudio
mkdir build-bb
cd build-bb
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    ..
make
make install
install_license "../LICENSE.txt"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libportaudio", :libportaudio),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Build against `ALSA` on Linux
    Dependency("alsa_jll"; platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

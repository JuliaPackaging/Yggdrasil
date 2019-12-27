# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libportaudio"
version = v"19.6.0"

# Collection of sources required to build libportaudio. Not all of these
# are used for all platforms.
sources = [
    "http://portaudio.com/archives/pa_stable_v190600_20161030.tgz" =>
    "f5a21d7dcd6ee84397446fa1fa1a0675bb2e8a4a6dceb4305a8404698d8d1513",

    # This includes the sources for libpa_shim
    "./bundled",

    # uncomment the following lines to include ASIO support. To distribute the
    # resulting binaries you'll need to sign the licence agreement included with
    # the SDK at: https://www.steinberg.net/en/company/developers.html

    # "http://www.steinberg.net/sdk_downloads/ASIOSDK2.3.1.zip" =>
    #     "31074764475059448a9b7a56f103f4723ed60465e0e9d1a9446ca03dcf840f04"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# move the ASIO SDK to where CMake can find it
if [ -d "asiosdk2.3.1" ]; then
    mv "asiosdk2.3.1 svnrev312937/ASIOSDK2.3.1" asiosdk2.3.1
fi

# Add the ringbuffer symbols needed by `pa_shim.c` to the windows export lists:
IDX=80
for SYM in PaUtil_GetRingBufferWriteAvailable \
           PaUtil_GetRingBufferReadAvailable \
           PaUtil_WriteRingBuffer \
           PaUtil_ReadRingBuffer; do
    echo "${SYM}    @${IDX}" >> ${WORKSPACE}/srcdir/portaudio/cmake_support/template_portaudio.def
    IDX=$((IDX+1))
done

# First, build libportaudio
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=ON \
    ../portaudio/
make
make install
install_license "${WORKSPACE}/srcdir/portaudio/LICENSE.txt"

# Next, build libpa_shim.  Note that we explicitly install to `${prefix}/lib` since that's
# what `portaudio` does, and we need to be together to get auto-moved.
cd ${WORKSPACE}/srcdir
SOURCEHASH=$(sha256sum pa_shim.c  | awk '{print $1}')
${CC} -O2 -fPIC '-DSOURCEHASH="${SOURCEHASH}"' -I${WORKSPACE}/srcdir/portaudio/include -I${WORKSPACE}/srcdir/portaudio/src/common pa_shim.c -lportaudio -o ${prefix}/lib/libpa_shim.${dlext} -shared
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libportaudio", :libportaudio),
    LibraryProduct("libpa_shim", :libpa_shim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

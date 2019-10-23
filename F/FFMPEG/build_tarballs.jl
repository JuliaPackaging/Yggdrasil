# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FFMPEG"
version = v"4.1.0"

# Collection of sources required to build FFMPEG
sources = [
    "https://ffmpeg.org/releases/ffmpeg-4.1.tar.bz2" =>
    "b684fb43244a5c4caae652af9022ed5d85ce15210835bce054a33fb26033a1a5",
]

# Bash recipe for building across all platforms
# TODO: Theora and Opus once their releases are available
script = raw"""
cd $WORKSPACE/srcdir
cd ffmpeg-4.1/
sed -i 's/-lflite"/-lflite -lasound"/' configure
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

export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig"
pkg-config --list-all

./configure            \
  --enable-cross-compile \
  --cross-prefix=/opt/${target}/bin/${target}- \
  --arch=${ccARCH}     \
  --target-os=${ccOS}  \
  --cc="${CC}"         \
  --cxx="${CXX}"       \
  --dep-cc="${CC}"     \
  --ar="${AR}"         \
  --nm="${NM}"         \
  --objcc="${CC} -ObjC" \
  --sysinclude=${prefix}/include \
  --pkg-config=$(which pkg-config) \
  --pkg-config-flags=--static \
  --prefix=$prefix     \
  --sysroot=/opt/${target}/${target}/sys-root \
  --extra-libs=-lpthread \
  --enable-gpl         \
  --enable-version3    \
  --enable-nonfree     \
  --disable-static     \
  --enable-shared      \
  --disable-debug      \
  --disable-doc        \
  --enable-avresample  \
  --enable-libass      \
  --enable-libfdk-aac  \
  --enable-libfreetype \
  --enable-libmp3lame  \
  --enable-libvorbis   \
  --enable-libx264     \
  --enable-libx265     \
  --enable-libvpx      \
  --enable-encoders    \
  --enable-decoders    \
  --enable-muxers      \
  --enable-demuxers    \
  --enable-parsers     \
  --extra-cflags="-I${prefix}/include" \
  --extra-ldflags="-L${prefix}/lib"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ffmpeg", :ffmpeg),
    ExecutableProduct("ffprobe", :ffprobe),
    ExecutableProduct("x264", :x264),
    ExecutableProduct("x265", :x265),
    LibraryProduct("libavformat", :libavformat),
    LibraryProduct("libavcodec", :libavcodec),
    LibraryProduct("libavutil", :libavutil),
    LibraryProduct("libpostproc", :libpostproc),
    LibraryProduct("libswresample", :libswresample),
    LibraryProduct("libavdevice", :libavdevice),
    LibraryProduct("libavresample", :libavresample),
    LibraryProduct("libavfilter", :libavfilter),
    LibraryProduct("libswscale", :libswscale)
]

# Dependencies that must be installed before this package can be built
# TODO: Theora and Opus once their releases are available
dependencies = [
    "libass_jll",
    "libfdk_jll",
    "fribidi_jll",
    "FreeType2_jll",
    "liblame_jll",
    "libvorbis_jll",
    "Ogg_jll",
    "LibVPX_jll",
    "x264Builder_jll",
    "x265Builder_jll",
    "Bzip2_jll",
    "Zlib_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

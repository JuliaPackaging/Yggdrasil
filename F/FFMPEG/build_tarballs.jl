# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "FFMPEG"
version = v"4.3.1"

# Collection of sources required to build FFMPEG
sources = [
    ArchiveSource("https://ffmpeg.org/releases/ffmpeg-$(version.major).$(version.minor).tar.bz2",
                  "a7e87112fc49ad5b59e26726e3a7cae0ffae511cba5376c579ba3cb04483d6e2"),
]

# Bash recipe for building across all platforms
# TODO: Theora once it's available
script = raw"""
cd $WORKSPACE/srcdir
cd ffmpeg-*/
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

if [[ "${target}" == arm-* ]]; then
    export CUDA_ARGS=""
elif [[ "${target}" == *-apple-* ]]; then
    export CUDA_ARGS=""
elif [[ "${target}" == *-unknown-freebsd* ]]; then
    export CUDA_ARGS=""
else
    export CUDA_ARGS="--enable-nvenc --enable-cuda-llvm"
fi

pkg-config --list-all

./configure            \
  --enable-cross-compile \
  --cross-prefix=/opt/${target}/bin/${target}- \
  --arch=${ccARCH}     \
  --target-os=${ccOS}  \
  --cc="${CC}"         \
  --cxx="${CXX}"       \
  --dep-cc="${CC}"     \
  --ar=ar              \
  --nm=nm              \
  --objcc="${OBJC}"    \
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
  --enable-pic         \
  --disable-debug      \
  --disable-doc        \
  --enable-avresample  \
  --enable-libass      \
  --enable-libfdk-aac  \
  --enable-libfreetype \
  --enable-libmp3lame  \
  --enable-libopus     \
  --enable-libvorbis   \
  --enable-libx264     \
  --enable-libx265     \
  --enable-libvpx      \
  --enable-encoders    \
  --enable-decoders    \
  --enable-muxers      \
  --enable-demuxers    \
  --enable-parsers     \
  --enable-openssl     \
  --disable-schannel   \
  --extra-cflags="-I${prefix}/include" \
  --extra-ldflags="-L${libdir}" ${CUDA_ARGS}
make -j${nproc}
make install
install_license LICENSE.md COPYING.*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ffmpeg", :ffmpeg),
    ExecutableProduct("ffprobe", :ffprobe),
    LibraryProduct(["libavcodec", "avcodec"], :libavcodec),
    LibraryProduct(["libavdevice", "avdevice"], :libavdevice),
    LibraryProduct(["libavfilter", "avfilter"], :libavfilter),
    LibraryProduct(["libavformat", "avformat"], :libavformat),
    LibraryProduct(["libavresample", "avresample"], :libavresample),
    LibraryProduct(["libavutil", "avutil"], :libavutil),
    LibraryProduct(["libpostproc", "postproc"], :libpostproc),
    LibraryProduct(["libswresample", "swresample"], :libswresample),
    LibraryProduct(["libswscale", "swscale"], :libswscale),
]

# Dependencies that must be installed before this package can be built
# TODO: Theora once it's available
dependencies = [
    BuildDependency("nv_codec_headers_jll"),
    Dependency("libass_jll"),
    Dependency("libfdk_aac_jll"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"),
    Dependency("LAME_jll"),
    Dependency("libvorbis_jll"),
    Dependency("Ogg_jll"),
    Dependency("LibVPX_jll"),
    Dependency("x264_jll"),
    Dependency("x265_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Opus_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")

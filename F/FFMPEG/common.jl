# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "FFMPEG"
version_string = "8.0.1"   # when patch number is zero, they use X.Y format
version = VersionNumber(version_string)

# Collection of sources required to build FFMPEG
sources = [
    ArchiveSource(
        "https://ffmpeg.org/releases/ffmpeg-$(version_string).tar.xz",
        "05ee0b03119b45c0bdb4df654b96802e909e0a752f72e4fe3794f487229e5a41",
    ),
    ## FFmpeg 6.1.1 does not work with macos 10.13 or earlier.
    get_macos_sdk_sources("10.13")...
]

# Bash recipe for building across all platforms
# TODO: Theora once it's available
function script(; ffplay=false, gpl=true)
    "FFPLAY=$(ffplay)\nGPL=$(gpl)\n" * get_macos_sdk_script("10.13") * raw"""
cd $WORKSPACE/srcdir
cd ffmpeg-*/
sed -i 's/-lflite"/-lflite -lasound"/' configure

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
elif [[ "${target}" == riscv64-* ]]; then
    export ccARCH="riscv64"
else
    export ccARCH="x86_64"
fi

export CUDA_ARGS=""

EXTRA_FLAGS=()
if [[ "${target}" == *-darwin* ]]; then
    EXTRA_FLAGS+=(--objcc="${CC} -x objective-c")
fi
if [[ "${FFPLAY}" == "true" ]]; then
    EXTRA_FLAGS+=("--enable-ffplay")
fi
# On Windows, use Schannel instead of OpenSSL
if [[ "${target}" == *-mingw* ]]; then
    EXTRA_FLAGS+=("--disable-openssl" "--enable-schannel")
else
    EXTRA_FLAGS+=("--enable-openssl" "--disable-schannel")
fi

# GPL and nonfree libraries
if [[ "${GPL}" == "true" ]]; then
    EXTRA_FLAGS+=("--enable-gpl" "--enable-nonfree")
    EXTRA_FLAGS+=("--enable-libfdk-aac" "--enable-libx264" "--enable-libx265")
fi

# Remove `-march` flags
sed -i 's/cpuflags="-march=$cpu"/cpuflags=""/g' configure

./configure            \
  --enable-cross-compile \
  --cross-prefix=/opt/${target}/bin/${target}- \
  --arch=${ccARCH}     \
  --target-os=${ccOS}  \
  --cc="${CC}"         \
  --cxx="${CXX}"       \
  --host-cc="${CC_BUILD}" \
  --dep-cc="${CC}"     \
  --ar=ar              \
  --nm=nm              \
  --sysinclude=${prefix}/include \
  --pkg-config=$(which pkg-config) \
  --pkg-config-flags=--static \
  --prefix=$prefix     \
  --sysroot=/opt/${target}/${target}/sys-root \
  --extra-libs=-lpthread \
  --enable-version3    \
  --disable-static     \
  --enable-shared      \
  --enable-pic         \
  --disable-debug      \
  --disable-doc        \
  --enable-libaom      \
  --enable-libass      \
  --enable-libfreetype \
  --enable-libmp3lame  \
  --enable-libopus     \
  --enable-libvorbis   \
  --enable-libvpx      \
  --enable-encoders    \
  --enable-decoders    \
  --enable-muxers      \
  --enable-demuxers    \
  --enable-parsers     \
  --extra-cflags="-I${prefix}/include" \
  --extra-ldflags="-L${libdir}" ${CUDA_ARGS} \
  "${EXTRA_FLAGS[@]}"
make -j${nproc}
if [[ "${FFPLAY}" == "true" ]]; then
    # Manually install only the FFplay binary
    install -Dvm 755 "ffplay${exeext}" "${bindir}/ffplay${exeext}"
else
    # Install all FFMPEG stuff: libraries, executables, header files, etc...
    make install
fi
install_license LICENSE.md COPYING.*
"""
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

preferred_gcc_version = v"8"

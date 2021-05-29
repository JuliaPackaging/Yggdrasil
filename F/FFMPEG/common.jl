# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FFMPEG"
version = v"4.4"

# Collection of sources required to build FFMPEG
sources = [
    ArchiveSource("https://ffmpeg.org/releases/ffmpeg-$(version.major).$(version.minor).tar.xz",
                  "06b10a183ce5371f915c6bb15b7b1fffbe046e8275099c96affc29e17645d909"),
]

# Bash recipe for building across all platforms
# TODO: Theora once it's available
function script(; ffplay=false)
    "FFPLAY=$(ffplay)\n" * raw"""
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

EXTRA_FLAGS=()
if [[ "${target}" == *-darwin* ]]; then
    EXTRA_FLAGS+=(--objcc="${CC} -x objective-c")
fi
if [[ "${FFPLAY}" == "true" ]]; then
    EXTRA_FLAGS+=("--enable-ffplay")
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
  --dep-cc="${CC}"     \
  --ar=ar              \
  --nm=nm              \
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
  --extra-ldflags="-L${libdir}" ${CUDA_ARGS} \
  "${EXTRA_FLAGS[@]}"
make -j${nproc}
if [[ "${FFPLAY}" == "true" ]]; then
    # Manually install only the FFplay binary
    mv "ffplay${exeext}" "${bindir}/ffplay${exeext}"
else
    # Install all FFMPEG stuff: libraries, executables, header files, etc...
    make install
fi
install_license LICENSE.md COPYING.*
"""
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

preferred_gcc_version = v"8"

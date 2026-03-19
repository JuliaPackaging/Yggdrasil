using BinaryBuilder, Pkg

name = "libsoundio"
version = v"2.0.0+1"

sources = [
    GitSource("https://github.com/andrewrk/libsoundio.git",
              "5087ef68b9c9014883861832c2f6dd8c6515f8e0")
]

script = raw"""
cd $WORKSPACE/srcdir/libsoundio

# Safe, portable optimization flags with thin LTO
export CFLAGS="-O3 -funroll-loops -fno-plt -flto"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-Wl,-O1 -flto"

# Base CMake flags
CMAKE_FLAGS=(
    "-DCMAKE_INSTALL_PREFIX=$prefix"
    "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON"
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_STATIC_LIBS=OFF"
    "-DBUILD_EXAMPLE_PROGRAMS=OFF"
    "-DBUILD_TESTS=OFF"
    "-DENABLE_JACK=OFF"
)

# Platform-specific audio backends
case "${target}" in
    *linux*)
        CMAKE_FLAGS+=(
            "-DENABLE_ALSA=ON"
            "-DENABLE_PULSEAUDIO=ON"
            "-DENABLE_COREAUDIO=OFF"
            "-DENABLE_WASAPI=OFF"
        )
        ;;
    *apple*)
        CMAKE_FLAGS+=(
            "-DENABLE_ALSA=OFF"
            "-DENABLE_PULSEAUDIO=OFF"
            "-DENABLE_COREAUDIO=ON"
            "-DENABLE_WASAPI=OFF"
        )
        ;;
    *w64*)
        CMAKE_FLAGS+=(
            "-DENABLE_ALSA=OFF"
            "-DENABLE_PULSEAUDIO=OFF"
            "-DENABLE_COREAUDIO=OFF"
            "-DENABLE_WASAPI=ON"
        )
        ;;
    *)
        CMAKE_FLAGS+=(
            "-DENABLE_ALSA=OFF"
            "-DENABLE_PULSEAUDIO=OFF"
            "-DENABLE_COREAUDIO=OFF"
            "-DENABLE_WASAPI=OFF"
        )
        ;;
esac

cmake -B build "${CMAKE_FLAGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license ./LICENSE
"""

platforms = supported_platforms()
filter!(p -> !Sys.isfreebsd(p), platforms)

products = [
    LibraryProduct("libsoundio", :libsoundio)
]

dependencies = [
    Dependency(PackageSpec(name="alsa_jll",
                           uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e");
               platforms=filter(Sys.islinux, platforms)),
    Dependency(PackageSpec(name="PulseAudio_jll",
                           uuid="02771fc1-bdb7-5db5-8d11-300768e00fbd");
               platforms=filter(Sys.islinux, platforms))
]

build_tarballs(ARGS, name, version, sources, script, platforms,
               products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"13.2.0")

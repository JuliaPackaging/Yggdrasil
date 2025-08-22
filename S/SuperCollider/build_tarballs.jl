using BinaryBuilder, Pkg

name = "SuperCollider"
version = v"3.14.0"

sources = [
    GitSource("https://github.com/supercollider/supercollider.git", "d263b8cc9905302bb6cfc26e8e68f22bb43092e9")
]

script = raw"""
cd ${WORKSPACE}/srcdir/supercollider
git submodule update --init --recursive

EXTRA_CMAKE_ARGS=()
# NOTE supernova does not support coreaudio on Apple platforms yet, so we force portaudio
# if [[ "${target}" == *-apple-* ]]; then
#     EXTRA_CMAKE_ARGS+=(-DAUDIOAPI=coreaudio)
# else
    EXTRA_CMAKE_ARGS+=(-DAUDIOAPI=portaudio)
# fi

$host_bindir/cmake -G Ninja \
    -S . \
    -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING=OFF \
    -DENABLE_TESTSUITE=OFF \
    -DLIBSCSYNTH=ON \
    -DSC_QT=OFF \
    -DSC_IDE=OFF \
    -DSC_ABLETON_LINK=OFF \
    -DSC_HIDAPI=OFF \
    -DSUPERNOVA=ON \
    -DNO_X11=ON \
    -DSCLANG_SERVER=OFF \
    -DINSTALL_HELP=OFF \
    "${EXTRA_CMAKE_ARGS[@]}"

# $host_bindir/cmake --build build --parallel ${nproc} --target scsynth supernova

# NOTE sclang fails to build on cross-compiled macOS
# $host_bindir/cmake --build build --parallel ${nproc} --target sclang

$host_bindir/cmake --build build --target server/install
"""

platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

products = [
    ExecutableProduct("scsynth", :scsynth),
    LibraryProduct("libscsynth", :libscsynth),
    ExecutableProduct("supernova", :supernova),
    # ExecutableProduct("sclang", :sclang),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("libportaudio_jll", v"19.7.0"),
    Dependency("libsndfile_jll", v"1.1.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")

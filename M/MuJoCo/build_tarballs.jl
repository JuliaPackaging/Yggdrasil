# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MuJoCo"
version = v"3.1.6"

# Collection of sources required to build mujoco
sources = [
    GitSource("https://github.com/google-deepmind/mujoco", "21bc6e5ce41b09d80a8b8df30f6fc866b81a152b"),
    DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mujoco
CXXFLAGS="-I${includedir}"

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/mingw.patch
elif [[ "${target}" == *-apple-darwin* ]]; then
    atomic_patch -p1 ../patches/macos.patch
    export MACOSX_DEPLOYMENT_TARGET=11
else
    atomic_patch -p1 ../patches/other.patch
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around using links from https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/1185
    # We only need libc++ - so no need to download the entire SDK definitions, otherwise linker will get an error
    cp -fr ../macoslibc/* "/opt/${target}/${target}/sys-root/usr/lib/."
fi

mkdir build
cd build

cmake \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE=Release \
  -DMUJOCO_BUILD_EXAMPLES=OFF \
  -DMUJOCO_BUILD_SIMULATE=OFF \
  -DMUJOCO_BUILD_TESTS=OFF \
  -DMUJOCO_TEST_PYTHON_UTIL=OFF \
  ..
cmake --build .
cmake --install .

# Copy license across manually
mkdir -p $prefix/share/licenses/MuJoCo
cp $WORKSPACE/srcdir/mujoco/LICENSE $prefix/share/licenses/MuJoCo/
"""
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux", libc="glibc"),
    Platform("x86_64", "linux", libc="glibc"),
    Platform("powerpc64le", "linux", libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
]

products = [
    LibraryProduct("libmujoco", :libmujoco)
]

linux_platforms = [p for p in platforms if Sys.islinux(p) || Sys.isfreebsd(p)]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_libX11_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXrandr_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXi_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXinerama_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXcursor_jll"; platforms=linux_platforms)
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")

using BinaryBuilder

name = "Notcurses"
version = v"3.0.9"
sources = [
    GitSource("https://github.com/dankamongmen/notcurses",
              "040ff99fb7ed6dee113ce303223f75cd8a38976c"),
    DirectorySource("bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/notcurses*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/repent.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-also-look-for-shared-libraries-on-Windows.patch

if [[ $target == *mingw* ]]; then
    export CFLAGS="${CFLAGS} -D_WIN32_WINNT=0x0600"
    cp ${WORKSPACE}/srcdir/headers/pthread_time.h "/opt/${target}/${target}/sys-root/include/pthread_time.h"
fi

# export CFLAGS="${CFLAGS} -I${includedir}"

FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
       -DCMAKE_INSTALL_PREFIX=${prefix}
       -DCMAKE_BUILD_TYPE=Release
       -DBUILD_EXECUTABLES=ON
       -DBUILD_SHARED_LIBS=ON
       -DUSE_CXX=OFF
       -DUSE_DOCTEST=OFF
       -DUSE_MULTIMEDIA=ffmpeg
       -DUSE_PANDOC=OFF
       -DUSE_POC=OFF
       -DUSE_QRCODEGEN=OFF
       -DUSE_STATIC=OFF
       )

cmake -B build "${FLAGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

# The products that we will ensure are always built.
products = [
    ExecutableProduct("notcurses-demo", :notcurses_demo),
    ExecutableProduct("notcurses-info", :notcurses_info),
    ExecutableProduct("notcurses-tester", :notcurses_tester),
    LibraryProduct("libnotcurses", :libnotcurses),
    LibraryProduct("libnotcurses-core", :libnotcurses_core),
    LibraryProduct("libnotcurses-ffi", :libnotcurses_ffi),
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    Dependency("FFMPEG_jll"),
    Dependency("Ncurses_jll"),
    Dependency("libdeflate_jll"),
    Dependency("libunistring_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

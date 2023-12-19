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
    cp ${WORKSPACE}/srcdir/headers/pthread_time.h /opt/${target}/${target}/sys-root/include/pthread_time.h
fi

multimedia=ffmpeg
if [[ ${bb_full_target} == armv6l-* ]]; then
    # FFMpeg is not available on armv6l
    multimedia=none
elif [[ ${target} == *mingw* ]]; then
    # FFMpeg is not found (why?)
    # We patch CMakelists.txt for shared libraries in Windows, maybe this goes wrong?
    multimedia=none
fi

FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
       -DCMAKE_INSTALL_PREFIX=${prefix}
       -DCMAKE_BUILD_TYPE=Release
       -DBUILD_EXECUTABLES=ON
       -DBUILD_SHARED_LIBS=ON
       -DUSE_CXX=OFF
       -DUSE_DOCTEST=OFF
       -DUSE_MULTIMEDIA=${multimedia}
       -DUSE_PANDOC=OFF
       -DUSE_POC=OFF
       -DUSE_QRCODEGEN=OFF
       -DUSE_STATIC=OFF
       )

if [[ ${target} == aarch64-apple-* ]]; then
    # We need `libgcc` for the function `__divdc3`.
    # We specify an explicit path name because there is no development version of this library.
    # It's likely that `FFmpeg` doesn't properly declare its dependency on this library.
    FLAGS+=(-DCMAKE_EXE_LINKER_FLAGS_INIT=${libdir}/libgcc_s.1.1.dylib)
fi

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
               julia_compat="1.6", preferred_gcc_version=v"9")

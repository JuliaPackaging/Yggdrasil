using BinaryBuilder

name = "Notcurses"
version = v"3.0.9"
sources = [
    GitSource("https://github.com/dankamongmen/notcurses",
        "040ff99fb7ed6dee113ce303223f75cd8a38976c"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/notcurses*/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/repent.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-also-look-for-shared-libraries-on-Windows.patch

if [[ $target == *mingw* ]]; then
    export CFLAGS="${CFLAGS} -D_WIN32_WINNT=0x0600"
    cp ${WORKSPACE}/srcdir/headers/pthread_time.h "/opt/${target}/${target}/sys-root/include/pthread_time.h"
fi

install_license COPYRIGHT

mkdir build && cd build

export CFLAGS="${CFLAGS} -I${includedir}"

FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
       -DCMAKE_INSTALL_PREFIX=${prefix}
       -DCMAKE_BUILD_TYPE=Release
       -DBUILD_SHARED_LIBS=ON
       -DUSE_DOCTEST=off
       -DUSE_PANDOC=off
       -DUSE_STATIC=off
       -DUSE_QRCODEGEN=off
       -DBUILD_EXECUTABLES=off
       -DUSE_POC=off
       -DUSE_MULTIMEDIA=none
       -DUSE_CXX=off
       )

cmake .. "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built.
products = [
    LibraryProduct("libnotcurses", :libnotcurses)
    LibraryProduct("libnotcurses-core", :libnotcurses_core)
    LibraryProduct("libnotcurses-ffi", :libnotcurses_ffi)
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    Dependency("Ncurses_jll"),
    Dependency("libunistring_jll"),
    Dependency("libdeflate_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")

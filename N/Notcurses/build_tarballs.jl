using BinaryBuilder

name = "Notcurses"
version = v"3.0.0"
sources = [
    GitSource("https://github.com/dankamongmen/notcurses",
              "d49a0375b762c9ec60ffb9e35b973643acfd69ab"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/notcurses*/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/repent.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-add-an-option-to-not-build-binaries.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-check-__MINGW32__-instead-of-__MINGW64__.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-also-look-for-shared-libraries-on-Windows.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-fix-Secur32-library-to-be-lowercase.patch

if [[ $target == *-w64-* ]]; then
    export CFLAGS="${CFLAGS} -D_WIN32_WINNT=0x0600"
    cp ${WORKSPACE}/srcdir/headers/pthread_time.h /opt/x86_64-w64-mingw32/x86_64-w64-mingw32/sys-root/include/pthread_time.h
fi

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
       -DBUILD_BINARIES=off
       -DUSE_POC=off
       -DUSE_MULTIMEDIA=none
       -D_WIN32_WINNT=0x0602
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
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    Dependency("Ncurses_jll"),
    Dependency("libunistring_jll"),
    Dependency("libdeflate_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")

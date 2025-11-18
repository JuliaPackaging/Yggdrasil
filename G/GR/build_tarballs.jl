# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../../fancy_toys.jl")  # for `should_build_platform`

name = "GR"
version = v"0.73.18"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sciapp/gr.git", "e495bada9e993664a8e680e574a1db1f49aef64f"),
    FileSource("https://github.com/sciapp/gr/releases/download/v$version/gr-$version.js",
               "bb027f21ba968ceea8b0c70a5259223d8c9572918e80deb3e047370c04bd91c4", "gr.js"),
    ArchiveSource("https://github.com/roblabla/MacOSX-SDKs/releases/download/macosx14.0/MacOSX14.0.sdk.tar.xz",
                  "4a31565fd2644d1aec23da3829977f83632a20985561a2038e198681e7e7bf49")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gr

update_configure_scripts

make -C 3rdparty/qhull -j${nproc}

if [[ $target == *"mingw"* ]]; then
    winflags=-DCMAKE_C_FLAGS="-D_WIN32_WINNT=0x0f00"
    tifflags=-DTIFF_LIBRARY=${libdir}/libtiff-6.dll
else
    tifflags=-DTIFF_LIBRARY=${libdir}/libtiff.${dlext}
fi

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    apple_sdk_root=$WORKSPACE/srcdir/MacOSX14.0.sdk
    sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
    export MACOSX_DEPLOYMENT_TARGET=12
fi

if [[ "${target}" == *apple* ]]; then
    make -C 3rdparty/zeromq ZEROMQ_EXTRA_CONFIGURE_FLAGS="--host=${target}"
fi

if [[ "${target}" == arm-* ]]; then
    export CXXFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
fi

mkdir build
cd build
cmake $winflags -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DGR_USE_BUNDLED_LIBRARIES=ON $tifflags -DCMAKE_BUILD_TYPE=Release ..

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
cp ../../gr.js ${libdir}/

install_license $WORKSPACE/srcdir/gr/LICENSE.md

if [[ $target == *"apple-darwin"* ]]; then
    cd ${bindir}
    ln -s ../Applications/gksqt.app/Contents/MacOS/gksqt ./
    ln -s ../Applications/grplot.app/Contents/MacOS/grplot ./
    ln -s ../Applications/GKSTerm.app/Contents/MacOS/GKSTerm ./
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("armv7l",  "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64",  "linux"; libc="glibc"),
    Platform("i686",  "linux"; libc="glibc"),
    Platform("powerpc64le",  "linux"; libc="glibc"),
    Platform("x86_64",  "windows"),
    Platform("i686",  "windows"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64",  "freebsd"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libGR", :libGR; dont_dlopen=true),
    LibraryProduct("libGR3", :libGR3; dont_dlopen=true),
    LibraryProduct("libGRM", :libGRM; dont_dlopen=true),
    LibraryProduct("libGKS", :libGKS; dont_dlopen=true),
    ExecutableProduct("gksqt", :gksqt),
    ExecutableProduct("grplot", :grplot),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("FFMPEG_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("GLFW_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("Pixman_jll"),
    HostBuildDependency("Qt6Base_jll"),
    Dependency("Qt6Base_jll"; compat="~6.8.2"), # Never allow upgrading more than the minor version without recompilation
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Zlib_jll"),
]

platforms_win = filter(Sys.iswindows, platforms)
platforms_rest = setdiff(platforms, platforms_win)

# Build the tarballs, and possibly a `build.jl` as well.
# GCC version 10 because of Qt6.7
if any(should_build_platform.(triplet.(platforms_win)))
    # GCC 12 and before fail with internal compiler error on mingw
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies;
                   preferred_gcc_version=v"13", julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms_rest)))
    build_tarballs(ARGS, name, version, sources, script, platforms_rest, products, dependencies;
                   preferred_gcc_version=v"10", julia_compat="1.6")
end

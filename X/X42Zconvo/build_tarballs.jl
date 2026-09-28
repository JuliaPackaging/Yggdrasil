# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "X42Zconvo"
version = v"2025.6.6"

sources = [
    GitSource("https://github.com/x42/zconvo.lv2.git",
              "ec2ff40b5f9701fdc2e3944657f3737b89be4b18"),
    # zconvo COPYING is GPLv2; zeta-convolver is v3-or-later.
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

install_license zconvo.lv2/COPYING
cp -v COPYING.GPL3 COPYING.zeta-convolver
install_license COPYING.zeta-convolver

# Upstream OPTIMIZATIONS carry -ffast-math and -msse*; displace them from the command line.
OPTIMIZATIONS="-O3 -fomit-frame-pointer -fno-finite-math-only -DNDEBUG"

# share/lv2 avoids BinaryBuilder's Windows audit moving lib/*.dll into bin/.
MAKE_EXTRA=(OPTIMIZATIONS="${OPTIMIZATIONS}" PREFIX="${prefix}" LV2DIR="${prefix}/share/lv2")
if [[ "${target}" == *-apple-* ]]; then
    # Cross builds do not report Darwin; the Makefile needs UNAME=Darwin for .dylib/strip.
    MAKE_EXTRA+=(UNAME=Darwin)
elif [[ "${target}" == *-mingw* ]]; then
    MAKE_EXTRA+=(XWIN="${target}")
elif [[ "${target}" == *-freebsd* ]]; then
    # meson lv2_jll puts lv2.pc in libdata/pkgconfig on FreeBSD.
    export PKG_CONFIG_PATH="${prefix}/libdata/pkgconfig:${PKG_CONFIG_PATH}"
fi

make -C zconvo.lv2 -j${nproc} "${MAKE_EXTRA[@]}"
make -C zconvo.lv2 install "${MAKE_EXTRA[@]}"
"""

products = [
    FileProduct("share/lv2/zeroconvo.lv2/manifest.ttl", :zconvo_lv2),
    LibraryProduct("zeroconvolv", :zconvo_bin, "share/lv2/zeroconvo.lv2"; dont_dlopen = true),
]

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("lv2_jll"; compat = "1.18.10"),
    Dependency("FFTW_jll"; compat = "3.3.11"),
    Dependency("libsndfile_jll"; compat = "1.2.2"),
    Dependency("libsamplerate_jll"; compat = "0.1.10"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", preferred_gcc_version = v"10")

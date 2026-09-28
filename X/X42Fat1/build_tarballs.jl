# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "X42Fat1"
version = v"2025.6.6"

sources = [
    GitSource("https://github.com/x42/fat1.lv2.git",
              "e61b0c093b3941fe960c2f99188cebd934bf6dbd"),
    # fat1 COPYING is GPLv2; resampler*.cc is v3-or-later — ship GPLv3 text from darc.
    GitSource("https://github.com/x42/darc.lv2.git",
              "0a00cdec44e80f282df4ca08bafcebb6c0499612"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

mkdir -p "${prefix}/share/licenses/X42Fat1"
cp fat1.lv2/COPYING "${prefix}/share/licenses/X42Fat1/COPYING"
cp darc.lv2/COPYING "${prefix}/share/licenses/X42Fat1/COPYING.resampler"

# Upstream OPTIMIZATIONS carry -ffast-math and -msse*; displace them from the command line.
OPTIMIZATIONS="-O3 -fomit-frame-pointer -fno-finite-math-only -DNDEBUG"

# share/lv2 avoids BinaryBuilder's Windows audit moving lib/*.dll into bin/.
MAKE_EXTRA=(OPTIMIZATIONS="${OPTIMIZATIONS}" BUILDOPENGL=no BUILDJACKAPP=no
            PREFIX="${prefix}" LV2DIR="${prefix}/share/lv2")
if [[ "${target}" == *-apple-* ]]; then
    # Keep-list for strip: RW defaults to a missing robtk/, so use local lv2syms.
    MAKE_EXTRA+=(UNAME=Darwin STRIPFLAGS="-u -r -arch all -s lv2syms")
elif [[ "${target}" == *-mingw* ]]; then
    MAKE_EXTRA+=(XWIN="${target}")
elif [[ "${target}" == *-freebsd* ]]; then
    # meson lv2_jll puts lv2.pc in libdata/pkgconfig on FreeBSD.
    export PKG_CONFIG_PATH="${prefix}/libdata/pkgconfig:${PKG_CONFIG_PATH}"
fi

# Without Makefile.git, `submodule_check` does not clone robtk (GUI only).
rm -f fat1.lv2/Makefile.git
if [[ "${target}" == *-apple-* ]]; then
    echo "_lv2_descriptor" > fat1.lv2/lv2syms
fi
make -C fat1.lv2 -j${nproc} "${MAKE_EXTRA[@]}"
make -C fat1.lv2 install "${MAKE_EXTRA[@]}"

find "${prefix}/share/lv2" -name lv2syms -delete
"""

products = [
    FileProduct("share/lv2/fat1.lv2/manifest.ttl", :fat1_lv2),
    LibraryProduct("fat1", :fat1_bin, "share/lv2/fat1.lv2"; dont_dlopen = true),
]

platforms = supported_platforms()

dependencies = [
    Dependency("lv2_jll"; compat = "1.18.10"),
    Dependency("FFTW_jll"; compat = "3.3.11"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", preferred_gcc_version = v"10")

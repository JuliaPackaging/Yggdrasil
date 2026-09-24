# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# The four x42-plugins submodules (https://github.com/x42/x42-plugins, meta-repo
# commit 3fb6abe, 2025-06-06) whose binaries are GPL-3.0-or-later, built headless
# for LV2 only. X42Plugins_jll carries the GPL-2.0-or-later submodules; keeping
# these apart leaves that artifact usable under GPLv2.
#
# darc: sources say v2-or-later, COPYING is the GPLv3 text.
# dpl:  peaklim.{cc,h} (Fons Adriaensen) are v3-or-later.
# fat1: resampler*.{cc,h} (zita-resampler, Fons Adriaensen) are v3-or-later.
# zconvo: zeta-convolver.{cc,h} (a modified zita-convolver) are v3-or-later.
# zconvo requires worker:schedule and options:options at instantiation.
name = "X42PluginsGPL3"
version = v"2025.6.6"

sources = [
    GitSource("https://github.com/x42/darc.lv2.git",
              "0a00cdec44e80f282df4ca08bafcebb6c0499612"),
    GitSource("https://github.com/x42/dpl.lv2.git",
              "e1967a54e399ff16790f4ec87fc481512f4359d3"),
    GitSource("https://github.com/x42/fat1.lv2.git",
              "e61b0c093b3941fe960c2f99188cebd934bf6dbd"),
    GitSource("https://github.com/x42/zconvo.lv2.git",
              "ec2ff40b5f9701fdc2e3944657f3737b89be4b18"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

mkdir -p "${prefix}/share/licenses/X42PluginsGPL3"
for d in darc dpl fat1 zconvo; do
    cp "${d}.lv2/COPYING" "${prefix}/share/licenses/X42PluginsGPL3/COPYING.${d}"
done

# Upstream OPTIMIZATIONS carry -ffast-math (rejected here) and -msse*; override
# from the command line so the definition is displaced entirely.
OPTIMIZATIONS="-O3 -fomit-frame-pointer -fno-finite-math-only -DNDEBUG"

# Install under share/lv2, not lib/lv2: BinaryBuilder's Windows audit moves
# every .dll under lib/ into bin/, which breaks LV2 bundles whose manifests
# name <plugin.dll> beside the ttl.
# INLINEDISPLAY=no drops the cairo/pango inline display from darc and dpl.
MAKE_EXTRA=(OPTIMIZATIONS="${OPTIMIZATIONS}" BUILDOPENGL=no BUILDJACKAPP=no
            INLINEDISPLAY=no PREFIX="${prefix}" LV2DIR="${prefix}/share/lv2")
if [[ "${target}" == *-apple-* ]]; then
    # The Makefiles strip with `-s $(RW)lv2syms` and RW defaults to a missing
    # robtk checkout; point at a local keep-list so the entry point survives.
    MAKE_EXTRA+=(UNAME=Darwin STRIPFLAGS="-u -r -arch all -s lv2syms")
elif [[ "${target}" == *-mingw* ]]; then
    MAKE_EXTRA+=(XWIN="${target}")
elif [[ "${target}" == *-freebsd* ]]; then
    # lv2_jll is built with meson, which installs lv2.pc under libdata/pkgconfig
    # on FreeBSD; that directory is not on BinaryBuilder's default search path.
    export PKG_CONFIG_PATH="${prefix}/libdata/pkgconfig:${PKG_CONFIG_PATH}"
fi

for d in darc.lv2 dpl.lv2 fat1.lv2 zconvo.lv2; do
    # Without Makefile.git, `submodule_check` does not clone robtk (GUI only).
    rm -f "${d}/Makefile.git"
    if [[ "${target}" == *-apple-* ]]; then
        echo "_lv2_descriptor" > "${d}/lv2syms"
    fi
    make -C "${d}" -j${nproc} "${MAKE_EXTRA[@]}"
    make -C "${d}" install "${MAKE_EXTRA[@]}"
done

find "${prefix}/share/lv2" -name lv2syms -delete
"""

# Manifests for Julia path discovery; LibraryProducts so a missing binary
# fails the audit. LibraryProduct.locate also searches bin/, which is why the
# bundles live under share/lv2 rather than lib/.
products = [
    FileProduct("share/lv2/darc.lv2/manifest.ttl", :darc_lv2),
    FileProduct("share/lv2/dpl.lv2/manifest.ttl", :dpl_lv2),
    FileProduct("share/lv2/fat1.lv2/manifest.ttl", :fat1_lv2),
    FileProduct("share/lv2/zeroconvo.lv2/manifest.ttl", :zconvo_lv2),
    LibraryProduct("darc", :darc_bin, "share/lv2/darc.lv2"; dont_dlopen = true),
    LibraryProduct("dpl", :dpl_bin, "share/lv2/dpl.lv2"; dont_dlopen = true),
    LibraryProduct("fat1", :fat1_bin, "share/lv2/fat1.lv2"; dont_dlopen = true),
    LibraryProduct("zeroconvolv", :zconvo_bin, "share/lv2/zeroconvo.lv2"; dont_dlopen = true),
]

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("lv2_jll"),
    # fat1 and zconvo link libfftw3f.
    Dependency("FFTW_jll"),
    # zconvo reads impulse responses with libsndfile and resamples them.
    Dependency("libsndfile_jll"),
    Dependency("libsamplerate_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", preferred_gcc_version = v"10")

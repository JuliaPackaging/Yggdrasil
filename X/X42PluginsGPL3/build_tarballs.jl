# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Headless LV2 builds of the GPL-3.0-or-later x42 plugins. fat1 and zconvo
# link v3-or-later objects whose upstream COPYING is still the GPLv2 text.
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
# fat1/zconvo COPYING is GPLv2; install GPLv3 text for the linked v3 objects.
cp darc.lv2/COPYING "${prefix}/share/licenses/X42PluginsGPL3/COPYING.fat1-resampler"
cp darc.lv2/COPYING "${prefix}/share/licenses/X42PluginsGPL3/COPYING.zconvo-zeta-convolver"

# Upstream OPTIMIZATIONS carry -ffast-math and -msse*; displace them from the command line.
OPTIMIZATIONS="-O3 -fomit-frame-pointer -fno-finite-math-only -DNDEBUG"

# share/lv2 avoids BinaryBuilder's Windows audit moving lib/*.dll into bin/.
MAKE_EXTRA=(OPTIMIZATIONS="${OPTIMIZATIONS}" BUILDOPENGL=no BUILDJACKAPP=no
            INLINEDISPLAY=no PREFIX="${prefix}" LV2DIR="${prefix}/share/lv2")
if [[ "${target}" == *-apple-* ]]; then
    # Keep-list for strip: RW defaults to a missing robtk/, so use local lv2syms.
    MAKE_EXTRA+=(UNAME=Darwin STRIPFLAGS="-u -r -arch all -s lv2syms")
elif [[ "${target}" == *-mingw* ]]; then
    MAKE_EXTRA+=(XWIN="${target}")
elif [[ "${target}" == *-freebsd* ]]; then
    # meson lv2_jll puts lv2.pc in libdata/pkgconfig on FreeBSD.
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
    Dependency("lv2_jll"; compat = "1.18.10"),
    Dependency("FFTW_jll"; compat = "3.3.11"),
    Dependency("libsndfile_jll"; compat = "1.2.2"),
    Dependency("libsamplerate_jll"; compat = "0.1.10"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", preferred_gcc_version = v"10")

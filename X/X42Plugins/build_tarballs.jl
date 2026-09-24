# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Robin Gareus' x42-plugins (https://github.com/x42/x42-plugins), LV2 only,
# headless DSP: the 14 submodules that are GPL-2.0-or-later throughout and build
# without OpenGL/JACK/cairo. Pinned to meta-repo commit 3fb6abe (2025-06-06).
#
# GPL-2.0-or-later: every shipped source says "either version 2 ... or (at your
# option) any later version". Not packaged: dpl/fat1/meters/sisco/zconvo
# (GPL-3.0-or-later source); darc (sources are v2-or-later, but COPYING is
# GPLv3); meters/sisco also cannot build headless. fil4, tuna, spectra and
# mixtri are GPL-2.0-or-later but need cairo/OpenGL/libltc and are excluded too.
# midimap builds but needs worker:schedule at run time — still shipped so a
# host that offers it can use it.
name = "X42Plugins"
version = v"2025.6.6"

# Each submodule is its own GitSource: the meta-repo pins them, and GitSource
# does not recurse.
sources = [
    GitSource("https://github.com/x42/balance.lv2.git",
              "432f5550a83af98ee215a1bdb1761959693ace87"),
    GitSource("https://github.com/x42/controlfilter.lv2.git",
              "eac52432999429160c2e06e124097a50c37c38b4"),
    GitSource("https://github.com/x42/matrixmixer.lv2.git",
              "171769871580e64a3b39091305d874848c650c43"),
    GitSource("https://github.com/x42/mididebug.lv2.git",
              "f23e53a712ba8ec5d4815bbf5eb397bbab578f0a"),
    GitSource("https://github.com/x42/midifilter.lv2.git",
              "349a081c53296cacb75e9c19d30bf97c67553435"),
    GitSource("https://github.com/x42/midigen.lv2.git",
              "26afb285bdd2e00859b8717e91fc377f345cfa0a"),
    GitSource("https://github.com/x42/midimap.lv2.git",
              "bae60cf667ecd0fe1cea2b07af622318a3141af4"),
    GitSource("https://github.com/x42/nodelay.lv2.git",
              "95d3fed18df70cb7b37eb6c8b3b9cc8b15d8513c"),
    GitSource("https://github.com/x42/onsettrigger.lv2.git",
              "484ce7f73c6e7230ad8b5f692898320ae694a2a6"),
    GitSource("https://github.com/x42/phaserotate.lv2.git",
              "f093fa7e4d4f159fa7336654d3c514177f6f0c56"),
    GitSource("https://github.com/x42/stepseq.lv2.git",
              "42ab09c93f30edcf555a504c163d5d36c8bd386d"),
    GitSource("https://github.com/x42/stereoroute.lv2.git",
              "47de3b0562eec34fab86743410df510378f6a851"),
    GitSource("https://github.com/x42/testsignal.lv2.git",
              "b8e4984c0ca91a9c77688f338ea4cd116f11c50c"),
    GitSource("https://github.com/x42/xfade.lv2.git",
              "4023e5231a7a83f74f55ea38442a5261edd4cbfb"),
]

script = raw"""
cd ${WORKSPACE}/srcdir

# Distinct basenames: every submodule ships a file named COPYING.
mkdir -p "${prefix}/share/licenses/X42Plugins"
for d in balance controlfilter matrixmixer mididebug midifilter midigen midimap \
         nodelay onsettrigger phaserotate stepseq stereoroute testsignal xfade; do
    cp "${d}.lv2/COPYING" "${prefix}/share/licenses/X42Plugins/COPYING.${d}"
done

# Upstream OPTIMIZATIONS carry -ffast-math (rejected here) and -msse*; override
# from the command line so the definition is displaced entirely.
OPTIMIZATIONS="-O3 -fomit-frame-pointer -fno-finite-math-only -DNDEBUG"

# Install under share/lv2, not lib/lv2: BinaryBuilder's Windows audit moves
# every .dll under lib/ into bin/ when it sees a "simple buildsystem", which
# breaks LV2 bundles whose manifests name <plugin.dll> beside the ttl.
MAKE_EXTRA=(OPTIMIZATIONS="${OPTIMIZATIONS}" BUILDOPENGL=no BUILDJACKAPP=no
            PREFIX="${prefix}" LV2DIR="${prefix}/share/lv2")
if [[ "${target}" == *-apple-* ]]; then
    # Several Makefiles strip with `-s $(RW)lv2syms` and RW defaults to a
    # missing robtk checkout; point at a local keep-list instead so the LV2
    # entry point is retained without fetching the GUI toolkit.
    MAKE_EXTRA+=(UNAME=Darwin STRIPFLAGS="-u -r -arch all -s lv2syms")
fi
if [[ "${target}" == aarch64-apple-* ]]; then
    # onsettrigger's complex bandpass needs `__divdc3` from compiler-rt.
    # Gate on aarch64 only: LLVMCompilerRT_jll is not a dependency on x86_64.
    export LDFLAGS="-L${libdir}/darwin -lclang_rt.osx ${LDFLAGS}"
    MAKE_EXTRA+=(LDFLAGS="${LDFLAGS}")
elif [[ "${target}" == *-mingw* ]]; then
    MAKE_EXTRA+=(XWIN="${target}")
fi

for d in balance.lv2 controlfilter.lv2 matrixmixer.lv2 mididebug.lv2 \
         midifilter.lv2 midigen.lv2 midimap.lv2 nodelay.lv2 onsettrigger.lv2 \
         phaserotate.lv2 stepseq.lv2 stereoroute.lv2 testsignal.lv2 xfade.lv2; do
    # Keep-list only on macOS (STRIPFLAGS); elsewhere it would install as junk.
    if [[ "${target}" == *-apple-* ]]; then
        echo "_lv2_descriptor" > "${d}/lv2syms"
    fi
    make -C "${d}" -j${nproc} "${MAKE_EXTRA[@]}"
    make -C "${d}" install "${MAKE_EXTRA[@]}"
done

# Do not leave a stray lv2syms inside any installed bundle.
find "${prefix}/share/lv2" -name lv2syms -delete
"""

# Manifests for Julia path discovery; LibraryProducts so a missing binary
# fails the audit (manifest-only products would not). Installing under
# share/lv2 (not lib/) is what prevents BinaryBuilder's Windows auto-move
# of .dll files into bin/ — LibraryProduct.locate also searches bin/.
products = [
    FileProduct("share/lv2/balance.lv2/manifest.ttl", :balance_lv2),
    FileProduct("share/lv2/controlfilter.lv2/manifest.ttl", :controlfilter_lv2),
    FileProduct("share/lv2/matrixmixer.lv2/manifest.ttl", :matrixmixer_lv2),
    FileProduct("share/lv2/mididebug.lv2/manifest.ttl", :mididebug_lv2),
    FileProduct("share/lv2/midifilter.lv2/manifest.ttl", :midifilter_lv2),
    FileProduct("share/lv2/midigen.lv2/manifest.ttl", :midigen_lv2),
    FileProduct("share/lv2/midimap.lv2/manifest.ttl", :midimap_lv2),
    FileProduct("share/lv2/nodelay.lv2/manifest.ttl", :nodelay_lv2),
    FileProduct("share/lv2/onsettrigger.lv2/manifest.ttl", :onsettrigger_lv2),
    FileProduct("share/lv2/phaserotate.lv2/manifest.ttl", :phaserotate_lv2),
    FileProduct("share/lv2/stepseq_s8n8.lv2/manifest.ttl", :stepseq_lv2),
    FileProduct("share/lv2/stereoroute.lv2/manifest.ttl", :stereoroute_lv2),
    FileProduct("share/lv2/testsignal.lv2/manifest.ttl", :testsignal_lv2),
    FileProduct("share/lv2/xfade.lv2/manifest.ttl", :xfade_lv2),
    LibraryProduct("balance", :balance_bin, "share/lv2/balance.lv2"; dont_dlopen = true),
    LibraryProduct("controlfilter", :controlfilter_bin, "share/lv2/controlfilter.lv2"; dont_dlopen = true),
    LibraryProduct("matrixmixer", :matrixmixer_bin, "share/lv2/matrixmixer.lv2"; dont_dlopen = true),
    LibraryProduct("mididebug", :mididebug_bin, "share/lv2/mididebug.lv2"; dont_dlopen = true),
    LibraryProduct("midifilter", :midifilter_bin, "share/lv2/midifilter.lv2"; dont_dlopen = true),
    LibraryProduct("midigen", :midigen_bin, "share/lv2/midigen.lv2"; dont_dlopen = true),
    LibraryProduct("midimap", :midimap_bin, "share/lv2/midimap.lv2"; dont_dlopen = true),
    LibraryProduct("nodelay", :nodelay_bin, "share/lv2/nodelay.lv2"; dont_dlopen = true),
    LibraryProduct("onsettrigger", :onsettrigger_bin, "share/lv2/onsettrigger.lv2"; dont_dlopen = true),
    LibraryProduct("phaserotate", :phaserotate_bin, "share/lv2/phaserotate.lv2"; dont_dlopen = true),
    LibraryProduct("stepseq", :stepseq_bin, "share/lv2/stepseq_s8n8.lv2"; dont_dlopen = true),
    LibraryProduct("stereoroute", :stereoroute_bin, "share/lv2/stereoroute.lv2"; dont_dlopen = true),
    LibraryProduct("testsignal", :testsignal_bin, "share/lv2/testsignal.lv2"; dont_dlopen = true),
    LibraryProduct("xfade", :xfade_bin, "share/lv2/xfade.lv2"; dont_dlopen = true),
]

platforms = supported_platforms()

# Pin LLVMCompilerRT together with preferred_llvm_version (PCRE2, LibSSH2, …).
llvm_version = v"17.0.6"

dependencies = [
    Dependency("lv2_jll"),
    # phaserotate links libfftw3f at build and run time.
    Dependency("FFTW_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    # `__divdc3` for aarch64-apple (onsettrigger complex bandpass).
    BuildDependency(PackageSpec(name = "LLVMCompilerRT_jll",
                                uuid = "4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version = string(llvm_version));
                    platforms = [Platform("aarch64", "macos")]),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", preferred_gcc_version = v"10",
               preferred_llvm_version = llvm_version)

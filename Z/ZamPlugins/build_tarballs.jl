# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Damien Zammit's zam-plugins (https://github.com/zamaudio/zam-plugins), built
# as headless CLAP modules: compressors including multiband and the ZaMaximX2
# limiter, EQs, gates, delay/echo, tube and phono emulation, granular.
#
# GPL-2.0-or-later. Every plugin source in the tree carries "either version 2 of
# the License, or (at your option) any later version" and the repository's
# COPYING is the GPLv2 text.
#
# Sixteen of the nineteen plugins upstream builds by default. The three left out
# are left out on purpose:
#
#   * ZamVerb and ZamHeadX2 link the bundled zita-convolver 4.0.0, which is
#     GPL-3.0-**or-later** (lib/zita-convolver-4.0.0/zita-convolver.h: "either
#     version 3 of the License, or (at your option) any later version"). Those
#     two binaries would therefore be GPL-3.0-or-later while everything else
#     here is GPL-2.0-or-later, and shipping them in an artifact labelled
#     GPL-2.0-or-later would misstate what a user has.
#   * ZamNoise needs fftw3f. It is licence-compatible (FFTW is
#     GPL-2.0-or-later), but it is the only plugin that would pull a numerical
#     dependency into the artifact, so it is a separate decision.
#
# ZamChild670, ZamPiano, ZamSFZ and ZamSynth are not in upstream's default
# PLUGINS list and are not built here either.
name = "ZamPlugins"
version = v"4.5.0"

# Collection of sources required to complete build
sources = [
    # 4.5 is the release tag; upstream publishes no source tarball, so the
    # repository and its DPF submodule are fetched separately -- GitSource does
    # not recurse into submodules.
    GitSource("https://github.com/zamaudio/zam-plugins.git",
              "64cb54aa983a4caf1526060283fd87201c06ec49"),
    GitSource("https://github.com/DISTRHO/DPF.git",
              "461ea6d45d842d273ae4d53ad5490e43459419cc"),  # the dpf submodule pinned at zam-plugins 4.5
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
mv DPF/* zam-plugins/dpf/
cd zam-plugins
install_license COPYING NOTICE.DPF

# DPF's own BASE_OPTS is `-O3 -ffast-math ...` plus per-architecture `-mtune`
# and SIMD flags. `-ffast-math` is rejected by the build environment, and
# overriding the variable from the command line is what displaces the whole
# definition rather than fighting the conditionals that append to it; the
# architecture flags are the build environment's business anyway.
BASE_OPTS="-O3 -fdata-sections -ffunction-sections"

for p in ZamAutoSat ZamComp ZamCompX2 ZamDelay ZamDynamicEQ ZamEcho ZamEQ2 \
         ZamGate ZamGateX2 ZamGEQ31 ZamGrains ZaMaximX2 ZamPhono ZamTube \
         ZaMultiComp ZaMultiCompX2; do
    # HAVE_OPENGL=false takes DPF down to UI_TYPE=none, which is what keeps
    # X11, OpenGL and cairo out of the build. It has to be a command-line
    # variable, not an exported one: DPF assigns HAVE_OPENGL=true outright on
    # Windows and macOS, and a makefile assignment beats the environment.
    # Only the CLAP wrapper is built, so the LADSPA/LV2/VST2/VST3/AU wrappers
    # and the JACK standalone are never linked either.
    make -C "plugins/${p}" clap -j${nproc} HAVE_OPENGL=false BASE_OPTS="${BASE_OPTS}"
done

# `${prefix}/lib/clap` rather than `${libdir}/clap`, so that the modules sit at
# one path on every platform: a JLL hands the path out itself, and on Windows
# `${libdir}` is `bin`, which would make the product paths platform-dependent
# for no gain.
mkdir -p "${prefix}/lib/clap"
cp -r bin/*.clap "${prefix}/lib/clap/"
"""

# The products that we will ensure are always built
products = [
    # `.clap` modules are declared as files: they are shared objects under a
    # name LibraryProduct does not recognise, and a bundle directory on macOS.
    FileProduct("lib/clap/ZamAutoSat.clap", :zam_autosat_clap),
    FileProduct("lib/clap/ZamComp.clap", :zam_comp_clap),
    FileProduct("lib/clap/ZamCompX2.clap", :zam_comp_x2_clap),
    FileProduct("lib/clap/ZamDelay.clap", :zam_delay_clap),
    FileProduct("lib/clap/ZamDynamicEQ.clap", :zam_dynamic_eq_clap),
    FileProduct("lib/clap/ZamEcho.clap", :zam_echo_clap),
    FileProduct("lib/clap/ZamEQ2.clap", :zam_eq2_clap),
    FileProduct("lib/clap/ZamGate.clap", :zam_gate_clap),
    FileProduct("lib/clap/ZamGateX2.clap", :zam_gate_x2_clap),
    FileProduct("lib/clap/ZamGEQ31.clap", :zam_geq31_clap),
    FileProduct("lib/clap/ZamGrains.clap", :zam_grains_clap),
    FileProduct("lib/clap/ZaMaximX2.clap", :zam_maxim_x2_clap),
    FileProduct("lib/clap/ZamPhono.clap", :zam_phono_clap),
    FileProduct("lib/clap/ZamTube.clap", :zam_tube_clap),
    FileProduct("lib/clap/ZaMultiComp.clap", :zam_multi_comp_clap),
    FileProduct("lib/clap/ZaMultiCompX2.clap", :zam_multi_comp_x2_clap),
]

platforms = supported_platforms()

# Dependencies that must be installed before this package can be built
dependencies = [
    # libgcc_s, which the C++ artifacts link and the auditor cannot otherwise
    # resolve.
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")

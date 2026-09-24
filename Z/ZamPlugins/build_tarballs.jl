# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Damien Zammit's zam-plugins (https://github.com/zamaudio/zam-plugins), built
# as headless CLAP modules: compressors including multiband and the ZaMaximX2
# limiter, EQs, gates, delay/echo, tube and phono emulation, granular.
#
# GPL-2.0-or-later: every plugin source says "either version 2 ... or any later
# version". Sixteen of the nineteen plugins upstream builds by default:
#   * ZamVerb and ZamHeadX2 link bundled zita-convolver 4.0.0, which is
#     GPL-3.0-or-later, so shipping them would misstate the artifact's licence.
#   * ZamNoise needs fftw3f -- licence-compatible, but the only plugin that
#     would pull a numerical dependency in, so a separate decision.
# ZamChild670, ZamPiano, ZamSFZ and ZamSynth are not in upstream's default
# PLUGINS list.
name = "ZamPlugins"
version = v"4.5.0"

# Collection of sources required to complete build
sources = [
    # No source tarball upstream, and GitSource does not recurse into
    # submodules, so the repo and its DPF submodule are fetched separately.
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

# DPF's BASE_OPTS carries `-ffast-math`, which the build environment rejects,
# plus per-architecture flags that are its business rather than ours.
# Overriding from the command line displaces the whole definition.
BASE_OPTS="-O3 -fdata-sections -ffunction-sections"

for p in ZamAutoSat ZamComp ZamCompX2 ZamDelay ZamDynamicEQ ZamEcho ZamEQ2 \
         ZamGate ZamGateX2 ZamGEQ31 ZamGrains ZaMaximX2 ZamPhono ZamTube \
         ZaMultiComp ZaMultiCompX2; do
    # HAVE_OPENGL=false takes DPF to UI_TYPE=none, keeping X11, OpenGL and
    # cairo out. It must be a command-line variable: DPF assigns
    # HAVE_OPENGL=true outright on Windows and macOS, and a makefile
    # assignment beats the environment.
    make -C "plugins/${p}" clap -j${nproc} HAVE_OPENGL=false BASE_OPTS="${BASE_OPTS}"
done

# `lib/clap` rather than `${libdir}/clap`, which is `bin` on Windows, so the
# product paths are the same on every platform.
mkdir -p "${prefix}/lib/clap"
cp -r bin/*.clap "${prefix}/lib/clap/"
"""

# The products that we will ensure are always built
products = [
    # Files, not libraries: a `.clap` is a shared object under a name
    # LibraryProduct does not recognise, and a bundle directory on macOS.
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
    # libgcc_s, which the C++ artifacts link.
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")

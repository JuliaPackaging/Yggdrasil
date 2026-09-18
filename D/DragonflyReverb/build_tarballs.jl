# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Michael Willis' Dragonfly Reverb (https://michaelwillis.github.io/dragonfly-reverb/),
# built as four headless CLAP modules -- hall, room, plate and early reflections.
#
# GPL-3.0-or-later. The plugin sources carry "version 3 of the License, or any
# later version" headers and the repository's LICENSE is the GPLv3 text; the
# bundled Freeverb3 DSP under `common/freeverb/` is Teru Kamogashira's
# GPL-2.0-or-later, which combines into GPL-3.0-or-later. DPF is ISC and
# kiss_fft is BSD-3-Clause, neither of which constrains the result further.
name = "DragonflyReverb"
version = v"3.2.10"

# Collection of sources required to complete build
sources = [
    # The release source tarball rather than the git repository, because the
    # build needs DPF and a GitSource does not fetch submodules; this tarball
    # has it vendored under `dpf/`.
    ArchiveSource("https://github.com/michaelwillis/dragonfly-reverb/releases/download/$(version)/dragonfly-reverb-$(version)-src.tar.xz",
                  "18af55a9592c9f50c4d5f86c9d5159132735d9ba53d49e9cfe7169b3109f7743"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dragonfly-reverb-*
install_license LICENSE common/freeverb/COPYING common/kiss_fft/COPYING.txt dpf/LICENSE

# DPF's own BASE_OPTS is `-O3 -ffast-math ...` plus per-architecture `-mtune`
# and SIMD flags. `-ffast-math` is rejected by the build environment, and
# overriding the variable from the command line is what displaces the whole
# definition rather than fighting the conditionals that append to it; the
# architecture flags are the build environment's business anyway.
BASE_OPTS="-O3 -fdata-sections -ffunction-sections"

for p in dragonfly-hall-reverb dragonfly-room-reverb dragonfly-plate-reverb dragonfly-early-reflections; do
    # HAVE_OPENGL=false takes DPF down to UI_TYPE=none, which is what keeps
    # X11, OpenGL and cairo out of the build. It has to be a command-line
    # variable, not an exported one: DPF assigns HAVE_OPENGL=true outright on
    # Windows and macOS, and a makefile assignment beats the environment.
    # Only the CLAP wrapper is built, so the LV2/VST2/VST3 wrappers and the
    # JACK standalone are never linked either.
    make -C "plugins/${p}" clap -j${nproc} HAVE_OPENGL=false BASE_OPTS="${BASE_OPTS}"
done

# `cp -r` rather than install(1) because a `.clap` is a bundle directory on
# macOS, and `${prefix}/lib/clap` rather than `${libdir}/clap` so the modules
# sit at one path on every platform -- a JLL hands the path out itself, and
# `${libdir}` is `bin` on Windows.
mkdir -p "${prefix}/lib/clap"
cp -r bin/*.clap "${prefix}/lib/clap/"
"""

# The products that we will ensure are always built
products = [
    # `.clap` modules are declared as files: they are shared objects under a
    # name LibraryProduct does not recognise, and a bundle directory on macOS.
    FileProduct("lib/clap/DragonflyHallReverb.clap", :dragonfly_hall_clap),
    FileProduct("lib/clap/DragonflyRoomReverb.clap", :dragonfly_room_clap),
    FileProduct("lib/clap/DragonflyPlateReverb.clap", :dragonfly_plate_clap),
    FileProduct("lib/clap/DragonflyEarlyReflections.clap", :dragonfly_early_clap),
]

platforms = supported_platforms()

# Dependencies that must be installed before this package can be built
dependencies = [
    # libgcc_s, which the C++ artifact links and the auditor cannot otherwise
    # resolve.
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")

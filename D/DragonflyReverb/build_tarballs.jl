# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Michael Willis' Dragonfly Reverb (https://michaelwillis.github.io/dragonfly-reverb/),
# built as four headless CLAP modules -- hall, room, plate and early reflections.
#
# GPL-3.0-or-later: the plugin sources say "version 3 ... or any later version".
# Bundled Freeverb3 (`common/freeverb/`) is GPL-2.0-or-later, which combines
# into the same; DPF is ISC and kiss_fft BSD-3-Clause, neither constraining.
name = "DragonflyReverb"
version = v"3.2.10"

# Collection of sources required to complete build
sources = [
    # The release tarball, not the git repo: the build needs DPF and a
    # GitSource does not fetch submodules. This has it vendored under `dpf/`.
    ArchiveSource("https://github.com/michaelwillis/dragonfly-reverb/releases/download/$(version)/dragonfly-reverb-$(version)-src.tar.xz",
                  "18af55a9592c9f50c4d5f86c9d5159132735d9ba53d49e9cfe7169b3109f7743"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dragonfly-reverb-*
install_license LICENSE common/freeverb/COPYING common/kiss_fft/COPYING.txt dpf/LICENSE

# DPF's BASE_OPTS carries `-ffast-math`, which the build environment rejects,
# plus per-architecture flags that are its business rather than ours.
# Overriding from the command line displaces the whole definition.
BASE_OPTS="-O3 -fdata-sections -ffunction-sections"

for p in dragonfly-hall-reverb dragonfly-room-reverb dragonfly-plate-reverb dragonfly-early-reflections; do
    # HAVE_OPENGL=false takes DPF to UI_TYPE=none, keeping X11, OpenGL and
    # cairo out. It must be a command-line variable: DPF assigns
    # HAVE_OPENGL=true outright on Windows and macOS, and a makefile
    # assignment beats the environment.
    make -C "plugins/${p}" clap -j${nproc} HAVE_OPENGL=false BASE_OPTS="${BASE_OPTS}"
done

# `cp -r` because a `.clap` is a bundle directory on macOS, and `lib/clap`
# rather than `${libdir}/clap` so the path is the same on every platform.
mkdir -p "${prefix}/lib/clap"
cp -r bin/*.clap "${prefix}/lib/clap/"
"""

# The products that we will ensure are always built
products = [
    # Files, not libraries: a `.clap` is a shared object under a name
    # LibraryProduct does not recognise, and a bundle directory on macOS.
    FileProduct("lib/clap/DragonflyHallReverb.clap", :dragonfly_hall_clap),
    FileProduct("lib/clap/DragonflyRoomReverb.clap", :dragonfly_room_clap),
    FileProduct("lib/clap/DragonflyPlateReverb.clap", :dragonfly_plate_clap),
    FileProduct("lib/clap/DragonflyEarlyReflections.clap", :dragonfly_early_clap),
]

platforms = supported_platforms()

# Dependencies that must be installed before this package can be built
dependencies = [
    # libgcc_s, which the C++ artifact links.
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")

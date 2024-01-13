# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PortMidi"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PortMidi/portmidi.git", "b808babecdc5d05205467dab5c1006c5ac0fdfd4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/portmidi/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -B build
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.isfreebsd, supported_platforms())  # 'asound' build missing for freebsd


# The products that we will ensure are always built
products = [
    LibraryProduct("libportmidi", :libportmidi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"), platforms=filter(Sys.islinux, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

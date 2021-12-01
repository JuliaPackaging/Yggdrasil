# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenAL"
version = v"1.21.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kcat/openal-soft.git", "ae4eacf147e2c2340cc4e02a790df04c793ed0a9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openal-soft/
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DALSOFT_EXAMPLES=false

make -j${nproc}
make install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libopenal", :libopenal)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("alsa_jll"),
    Dependency("Ogg_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("PulseAudio_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")

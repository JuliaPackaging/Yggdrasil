# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenAL"
version = v"1.19.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kcat/openal-soft.git", "96aacac10ca852fc30fd7f72f3e3c6ddbe02858c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openal-soft/
cd build
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_UTILS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_NO_CONFIG_UTIL=true"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_EXAMPLES=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_TESTS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_CONFIG=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_HRTF_DEFS=false"
CMAKE_FLAGS="${CMAKE_FLAGS} -DALSOFT_AMBDEC_PRESETS=false"
cmake ${CMAKE_FLAGS} ..
make -j${nproc}
make install
install_license ../COPYING 

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc=:glibc),
    Platform("x86_64", "linux"; libc=:glibc),
    Platform("i686", "linux"; libc=:musl),
    Platform("x86_64", "linux"; libc=:musl),
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libopenal", :libopenal)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="alsa_jll", uuid="45378030-f8ea-5b20-a7c7-1a9d95efb90e"))
    Dependency(PackageSpec(name="Ogg_jll", uuid="e7412a2a-1a6e-54c0-be00-318e2571c051"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

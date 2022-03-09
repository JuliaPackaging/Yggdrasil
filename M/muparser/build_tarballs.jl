# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "muparser"
version = v"2.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/beltoforion/muparser/archive/refs/tags/v$(version).tar.gz", "b35fc84e3667d432e3414c8667d5764dfa450ed24a99eeef7ee3f6647d44f301")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/muparser-*

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
            -DCMAKE_BUILD_TYPE=Release
            -DENABLE_SAMPLES=OFF
            -DBUILD_TESTING=OFF
            -DBUILD_SHARED_LIBS=ON)

# Apple's Clang does not support OpenMP? - taken from AMRex build_tarballs.jl
if [[ ${target} == *-apple-* ]]; then

    CMAKE_FLAGS+=(-DENABLE_OPENMP=OFF)
    
else

    CMAKE_FLAGS+=(-DENABLE_OPENMP=ON)

fi

cmake . ${CMAKE_FLAGS[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))


# The products that we will ensure are always built
products = [
    LibraryProduct("libmuparser", :libmuparser)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
#linux-musl variants hav an same issue as https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387 on gcc 4, so use higher version
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7")

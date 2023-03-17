# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenEXR"
version = v"3.1.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/openexr.git", "3c3074026309dca667247e2544c4645b6fedeeca")
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openexr*
mkdir build
cd build/
cmake \
    -DBUILD_TESTING=OFF \
    -DOPENEXR_INSTALL_TOOLS=OFF \
    -DOPENEXR_INSTALL_EXAMPLES=OFF \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libOpenEXRUtil-3_1", :libOpenEXRUtil),
    LibraryProduct("libOpenEXRCore-3_1", :libOpenEXRCore),
    LibraryProduct("libOpenEXR-3_1", :libOpenEXR),
    LibraryProduct("libIlmThread-3_1", :libIlmThread),
    LibraryProduct("libIex-3_1", :libIex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Imath_jll"; compat="=3.1.7"),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", julia_compat = "1.6")

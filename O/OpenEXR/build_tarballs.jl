# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenEXR"
version = v"3.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v3.0.1.tar.gz", "6d14a8df938bbbd55dd6e55b24c527fe9323fe6a45f704e56967dfbf477cecc1")
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
    LibraryProduct("libOpenEXRUtil-3_0", :libOpenEXRUtil),
    LibraryProduct("libOpenEXR-3_0", :libOpenEXR),
    LibraryProduct("libIlmThread-3_0", :libIlmThread),
    LibraryProduct("libIex-3_0", :libIex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Imath_jll", uuid="905a6f67-0a94-5f89-b386-d35d92009cd1")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")

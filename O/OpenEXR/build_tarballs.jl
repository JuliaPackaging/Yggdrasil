# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenEXR"
version = v"3.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AcademySoftwareFoundation/openexr.git", "4a84390282584957ffaf1697c411f9ae7e420f2f"),
    GitSource("https://github.com/AcademySoftwareFoundation/Imath.git", "73c2cdfcaf2a22880ddf42a866ebd4614d424410")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir Imath/build
cd Imath/build/
cmake -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j
make install
cd ../..
mkdir openexr/build
cd openexr/build/
cmake -DOPENEXR_INSTALL_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("exrmaketiled", :exrmaketiled),
    LibraryProduct("libOpenEXR-3_0", :libOpenEXR),
    ExecutableProduct("exrstdattr", :exrstdattr),
    ExecutableProduct("exr2aces", :exr2aces),
    ExecutableProduct("exrmultipart", :exrmultipart),
    LibraryProduct("libImath-3_0", :libImath),
    LibraryProduct("libIex-3_0", :libIex),
    ExecutableProduct("exrheader", :exrheader),
    ExecutableProduct("exrmultiview", :exrmultiview),
    ExecutableProduct("exrmakepreview", :exrmakepreview),
    LibraryProduct("libOpenEXRUtil-3_0", :libOpenEXRUtil),
    ExecutableProduct("exrenvmap", :exrenvmap),
    LibraryProduct("libIlmThread-3_0", :libIlmThread)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")

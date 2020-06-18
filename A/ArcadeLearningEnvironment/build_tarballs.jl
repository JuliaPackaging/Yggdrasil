# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ArcadeLearningEnvironment"
version = v"0.6.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mgbellemare/Arcade-Learning-Environment/archive/v0.6.1.tar.gz", "8059a4087680da03878c1648a8ceb0413a341032ecaa44bef4ef1f9f829b6dde")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Arcade-Learning-Environment-0.6.1/
cmake -DUSE_SDL=OFF -DBUILD_EXAMPLES=OFF -DBUILD_CPP_LIB=OFF -DBUILD_CLI=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-I${prefix}/include" .
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libale_c", :libale_c)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

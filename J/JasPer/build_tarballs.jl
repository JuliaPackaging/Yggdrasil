# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JasPer"
version = v"2.0.33"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jasper-software/jasper", "fe00207dc10db1d7cc6f2757961c5c6bdfd10973"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/jasper*
mkdir jll_build

cmake -H. \
-B./jll_build \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DJAS_ENABLE_DOC=false \
-DJAS_ENABLE_OPENGL=false \
-DALLOW_IN_SOURCE_BUILD=true \
-DJAS_ENABLE_AUTOMATIC_DEPENDENCIES=false \
-DCMAKE_BUILD_TYPE=Release

cd jll_build/
make clean all
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libjasper", :libjasper),
    ExecutableProduct("imginfo", :imginfo),
    ExecutableProduct("jasper", :jasper),
    ExecutableProduct("imgcmp", :imgcmp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

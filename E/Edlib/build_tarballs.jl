# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Edlib"
version = v"1.2.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Martinsos/edlib.git", "ba4272ba68fcdbe31cbc10853de1841701e4e60a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/edlib/
# these programs do not link for some reason, but we don't need them
mv CMakeLists.txt CMakeLists.txt.orig
egrep -v "helloWorld|runTests|aligner" <CMakeLists.txt.orig >CMakeLists.txt
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON ..
make -j$nproc
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libedlib", :libedlib)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# gcc 6.1.0: there is a bug in stdlib on *-linux-musl in earlier versions (e.g. see https://patchwork.ozlabs.org/patch/544393/)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0")

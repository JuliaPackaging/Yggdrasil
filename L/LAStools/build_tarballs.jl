# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LAStools"
version = v"2.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LAStools/LAStools.git", "b2f578b4f03c9016d519b319cd61c903a74cf744")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# build the executable
mkdir LAStools/build
cd LAStools/build
cmake -S .. -B . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_CXX_FLAGS="-std=c++17 -Wno-narrowing" \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_VERBOSE_MAKEFILE=OFF
cmake --build . --target install --config Release

# make sure the license is there
install_license ../LICENSE.txt
# make sure the executable is properly installed
install -Dvm 755 -d "bin64" "${bindir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("las2las64", :las2las),
    ExecutableProduct("las2txt64", :las2txt),
    ExecutableProduct("lascopcindex64", :lascopcindex),
    ExecutableProduct("lasdiff64", :lasdiff),
    ExecutableProduct("lasindex64", :lasindex),
    ExecutableProduct("lasinfo64", :lasinfo),
    ExecutableProduct("lasmerge64", :lasmerge),
    ExecutableProduct("lasprecision64", :lasprecision),
    ExecutableProduct("laszip64", :laszip),
    ExecutableProduct("txt2las64", :txt2las)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p),  platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")

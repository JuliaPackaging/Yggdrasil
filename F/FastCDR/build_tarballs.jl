# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FastCDR"
version = v"1.0.27"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/eProsima/Fast-CDR.git", "5d782877435b569e0ed38541f362e212c9123dd4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Fast-CDR
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
install_license ../LICENSE
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libfastcdr", :libfastcdr_1)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Clipper"
version = v"6.4.3"

# Collection of sources required to build Clipper
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/polyclipping/clipper_ver6.4.2.zip", "a14320d82194807c4480ce59c98aa71cd4175a5156645c4e2b3edd330b930627"),
    DirectorySource("./cwrapper")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
cp cclipper.cpp ./cpp/cclipper.cpp
cd cpp
mkdir "${libdir}"
${CXX} -fPIC -std=c++11 -shared -o "${libdir}/libcclipper.${dlext}" clipper.cpp cclipper.cpp
cd ..
install_license License.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# The products that we will ensure are always built
products = [
    LibraryProduct("libcclipper", :libcclipper)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

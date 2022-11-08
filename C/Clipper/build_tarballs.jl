# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Clipper"
upstream_version = v"6.4.2"
version = v"6.4.3" # <-- This version is a lie, to build for new platforms

# Collection of sources required to build Clipper
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/polyclipping/clipper_ver$(upstream_version).zip",
                  "a14320d82194807c4480ce59c98aa71cd4175a5156645c4e2b3edd330b930627"),
    DirectorySource("./cwrapper")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cpp
cp ../cclipper.cpp ./cclipper.cpp
mkdir -p "${libdir}"
${CXX} -fPIC -std=c++11 -shared -o "${libdir}/libcclipper.${dlext}" clipper.cpp cclipper.cpp
install_license ../License.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# The products that we will ensure are always built
products = [
    LibraryProduct("libcclipper", :libcclipper)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

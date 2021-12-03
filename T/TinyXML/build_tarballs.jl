# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TinyXML"
version = v"2.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/tinyxml/tinyxml/$(version)/tinyxml_$(version.major)_$(version.minor)_$(version.patch).tar.gz",
                  "15bdfdcec58a7da30adc87ac2b078e4417dbe5392f3afb719f9ba6d062645593"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tinyxml

CPPFLAGS="-DTIXML_USE_STL"
CXXFLAGS="-fPIC -Wall -Wno-unknown-pragmas -Wno-format -O3"
c++ -c "${CPPFLAGS}" ${CXXFLAGS} tinyxml.cpp -o tinyxml.o
c++ -c "${CPPFLAGS}" ${CXXFLAGS} tinyxmlparser.cpp -o tinyxmlparser.o
c++ -c "${CPPFLAGS}" ${CXXFLAGS} tinyxmlerror.cpp -o tinyxmlerror.o
c++ -c "${CPPFLAGS}" ${CXXFLAGS} tinystr.cpp -o tinystr.o
mkdir -p "${libdir}"
c++ -shared -o "${libdir}/libtinyxml.${dlext}" tinyxml.o tinyxmlparser.o tinyxmlerror.o tinystr.o

mkdir -p "${includedir}"
cp *.h "${includedir}/."

install_license readme.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libtinyxml", :libtinyxml),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

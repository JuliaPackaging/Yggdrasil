# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TinyXML"
version = v"2.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/tinyxml/tinyxml/2.6.2/tinyxml_2_6_2.tar.gz", "15bdfdcec58a7da30adc87ac2b078e4417dbe5392f3afb719f9ba6d062645593")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/tinyxml

g++ -c -Wall -Wno-unknown-pragmas -Wno-format -O3   tinyxml.cpp -o tinyxml.o
g++ -c -Wall -Wno-unknown-pragmas -Wno-format -O3 tinyxmlparser.cpp -o tinyxmlparser.o
g++ -c -Wall -Wno-unknown-pragmas -Wno-format -O3 xmltest.cpp -o xmltest.o
g++ -c -Wall -Wno-unknown-pragmas -Wno-format -O3   tinyxmlerror.cpp -o tinyxmlerror.o
g++ -c -Wall -Wno-unknown-pragmas -Wno-format -O3   tinystr.cpp -o tinystr.o
g++ -o xmltest tinyxml.o tinyxmlparser.o xmltest.o tinyxmlerror.o tinystr.o  

mkdir -p ${bindir}
cp xmltest ${bindir}

install_license readme.txt

mkdir -p ${includedir}
cp *.h ${includedir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    FileProduct("bin/xmltest", :xmltest)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
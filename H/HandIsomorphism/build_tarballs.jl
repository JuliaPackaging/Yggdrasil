# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HandIsomorphism"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kdub0/hand-isomorphism.git", "dabcee4a84c1d62ee6ded9b6ff02ece6823fcc0f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license ${WORKSPACE}/srcdir/hand-isomorphism/LICENSE.txt
cp hand-isomorphism/LICENSE.txt $prefix/share/licenses/LICENSE.txt
cd hand-isomorphism/src/
mkdir $includedir
cp hand_index.h $includedir/hand_index.h
OS=$(uname)
if [[ "${target}" == *linux* ]] || [[ "${target}" == *freebsd* ]]; then     mkdir $prefix/lib/;     gcc -std=c99 -O2 -shared -o $prefix/lib/libhandisomorphism.so -fPIC deck.c hand_index.c -lm; elif [[ "${target}" == *mingw* ]]; then     mkdir $prefix/bin/;     gcc -std=c99 -O2 -shared -o $prefix/bin/libhandisomorphism.dll -fPIC deck.c hand_index.c -lm; elif [[ "${target}" == *apple* ]]; then          mkdir $prefix/lib/;     gcc -std=c99 -O2 -dynamiclib -o $prefix/lib/libhandisomorphism.dylib -fPIC deck.c hand_index.c -lm; fi
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhandisomorphism", :libhandisomorphism)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")

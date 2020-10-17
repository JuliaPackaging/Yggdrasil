# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Word2Vec"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tmikolov/word2vec.git", "20c129af10659f7c50e86e3be406df663beff438"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd word2vec/
export CFLAGS="-lm -pthread -O3 -Wall -funroll-loops -Wno-unused-result"
make word2vec
make word2phrase
mkdir -p $bindir
cp word2vec$exeext $bindir 
cp word2phrase$exeext $bindir 
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() 
# Too many posix assumptions
filter!(!Sys.iswindows, platforms) 

# The products that we will ensure are always built
products = [
    ExecutableProduct("word2vec", :word2vec)
    ExecutableProduct("word2phrase", :word2phrase)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

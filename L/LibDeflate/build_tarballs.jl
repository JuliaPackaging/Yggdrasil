# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibDeflate"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ebiggers/libdeflate/archive/v1.6.tar.gz", "60748f3f7b22dae846bc489b22a4f1b75eab052bf403dd8e16c8279f16f5171e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libdeflate-1.6/
if [ ${target} = "x86_64-w64-mingw32" ]; then
    TARGET=libdeflate.dll;
    RESULT=$TARGET
elif [ ${target} = "i686-w64-mingw32" ]; then
    TARGET=libdeflate.dll;
    RESULT=$TARGET
elif [ ${target} = "x86_64-apple-darwin14" ]; then
    TARGET=libdeflate.dylib;
    RESULT=libdeflate.0.dylib
else
    TARGET=libdeflate.so;
    RESULT=libdeflate.so.0
fi
make DISABLE_ZLIB=true "GCC=O3" ${TARGET}
mv ${RESULT} /workspace/destdir/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdeflate", :libdeflate)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

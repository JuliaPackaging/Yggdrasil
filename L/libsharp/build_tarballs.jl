# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsharp"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Libsharp/libsharp.git", "cc4753ff4b0ef393f0d4ada41a175c6d1dd85d71")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsharp
perl -pi -e 's/-ffast-math//' configure.ac
perl -pi -e 's/-march=native//' configure.ac
autoconf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-pic
make -j$(nproc)
cc -shared $(find . -name '*.o') -o libsharp.so -lgomp
mkdir ${prefix}/lib
cp libsharp.so ${prefix}/lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsharp", :libsharp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

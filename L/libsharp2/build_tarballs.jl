# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsharp2"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.mpcdf.mpg.de/mtr/libsharp.git", "54856313a5fcfb6a33817b7dfa28c4b1965ffbd1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libsharp/
sed -i 's/LT_INIT.*/LT_INIT\(\[win32-dll\]\)/g' configure.ac
sed -i 's/libsharp2_la_LDFLAGS = -version-info 0:0:0/libsharp2_la_LDFLAGS = -version-info 0:0:0 -no-undefined/g' Makefile.am
autoreconf -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsharp2", :libsharp2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

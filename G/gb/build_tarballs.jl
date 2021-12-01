# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gb"
version = v"0.17.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ederc/gb.git", "4b579882b5dccf8fbf2294838d34da35ae6adbb7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd gb
./autogen.sh 
./configure --enable-shared --disable-static --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgb", :libgb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"), v"6.1.2"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

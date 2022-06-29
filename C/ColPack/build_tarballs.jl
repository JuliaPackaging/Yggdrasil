# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ColPack"
version = v"0.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/michel2323/ColPack.git", "b22020d3915abc06753fafe7005e539f11d46924")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ColPack/build/automake/
autoreconf -vif
mkdir build
cd build/
../configure --disable-examples --disable-openmp --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --enable-shared
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libColPack", :libcolpack)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

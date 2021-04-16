# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mimalloc"
version = v"2.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/mimalloc.git", "8e35ccc43be293a9bfd6e63da310a79c235d25d9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mimalloc/
mkdir -p out/release
cd out/release/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DMI_BUILD_STATIC=OFF ../..
make -j ${nproc}
make -j ${nproc} install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("lib/mimalloc-2.0/mimalloc.o", :mimalloc),
    LibraryProduct("libmimalloc", :libmimalloc, "lib/mimalloc-2.0")
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0")

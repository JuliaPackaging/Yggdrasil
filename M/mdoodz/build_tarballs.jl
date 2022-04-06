# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mdoodz"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tduretz/MDOODZ7.0.git", "612340c414915bfbfdfeb32071e96ae8fba2ff5b"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd MDOODZ7.0.git/
rm makefile
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmdoodz", :libmdoodz)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CXSparse_jll", uuid="c77e7b6a-7cf9-58ed-a396-e1da12b05d87"))
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59"))
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
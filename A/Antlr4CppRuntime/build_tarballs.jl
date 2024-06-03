# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Antlr4CppRuntime"
version = v"4.13.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/antlr/antlr4/archive/refs/tags/$(version).tar.gz",
                  "efe4057d75ab48145d4683100fec7f77d7f87fa258707330cadd1f8e6f7eecae"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/antlr4*/runtime/Cpp
atomic_patch -p1 ../../../patches/forward-cmake-toolchain.patch
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install

# Remove large static library
rm "${prefix}/lib/libantlr4-runtime.a"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libantlr4-runtime", :libantlr4_cpp_runtime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libuuid_jll", uuid="38a345b3-de98-5d2b-a5d3-14cd9215e700"); platforms=filter(p -> !(Sys.iswindows(p) || Sys.isapple(p)), platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")

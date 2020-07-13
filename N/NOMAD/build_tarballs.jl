using BinaryBuilder

name = "NOMAD"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/amontoison/nomad.git","a15c91feb589451e6934b1544edb4360af8fbc41"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir/nomad"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/nomad-no-headers-generation.patch"
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    CC=gcc
    CXX=g++
fi
mkdir build
cd build
cmake -DNOMAD_WITH_OPENMP=OFF -DNOMAD_WITH_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libnomadInterface", :libnomadInterface),
    LibraryProduct("libnomadAlgos", :libnomadAlgos),
    LibraryProduct("libnomadEval", :libnomadEval),
    LibraryProduct("libnomadUtils", :libnomadUtils),
    LibraryProduct("libsgtelib", :libsgtelib),
    ExecutableProduct("nomad", :nomad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")

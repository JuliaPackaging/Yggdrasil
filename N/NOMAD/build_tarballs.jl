using BinaryBuilder, Pkg

name = "NOMAD"
version = v"4.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/amontoison/nomad.git","f6a4b4f18111372e3e7190b019e76ed86b915ddc"),
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
cmake -DTEST_OPENMP=OFF -DBUILD_INTERFACES=ON -DBUILD_LIBMODE_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(); skip=Sys.isapple)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnomadCInterface", :libnomadCInterface),
    LibraryProduct("libnomadAlgos", :libnomadAlgos),
    LibraryProduct("libnomadEval", :libnomadEval),
    LibraryProduct("libnomadUtils", :libnomadUtils),
    LibraryProduct("libsgtelib", :libsgtelib),
    ExecutableProduct("nomad", :nomad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "WaveFD"
version = v"0.1.0"

# Collection of sources required to build AzStorage
sources = [
    GitSource(
        "https://github.com/ChevronETC/WaveFD.jl.git",
        "52105fc62f8a52ade84365f403a352a47e3909d6"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/WaveFD.jl/src

CXXFLAGS="-funroll-loops"
if [[ "${target}" == i686-linux-gnu || "${target}" == x86_64-linux-gnu || "${target}" == powerpc6rle-linux-gnu ]]; then
    CXXFLAGS+=" -D__FUNCTION_CLONES__"
fi

echo "target=$target, CXXFLAGS=$CXXFLAGS"

cmake . -DCMAKE_CXX_FLAGS="${CXXFLAGS}" -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release
make VERBOSE=1
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libprop2DAcoIsoDenQ_DEO2_FDTD", :libprop2DAcoIsoDenQ_DEO2_FDTD),
    LibraryProduct("libprop2DAcoVTIDenQ_DEO2_FDTD", :libprop2DAcoVTIDenQ_DEO2_FDTD),
    LibraryProduct("libprop2DAcoTTIDenQ_DEO2_FDTD", :libprop2DAcoTTIDenQ_DEO2_FDTD),
    LibraryProduct("libprop3DAcoIsoDenQ_DEO2_FDTD", :libprop3DAcoIsoDenQ_DEO2_FDTD),
    LibraryProduct("libprop3DAcoVTIDenQ_DEO2_FDTD", :libprop3DAcoVTIDenQ_DEO2_FDTD),
    LibraryProduct("libprop3DAcoTTIDenQ_DEO2_FDTD", :libprop3DAcoTTIDenQ_DEO2_FDTD),
    LibraryProduct("libillumination", :libillumination),
    LibraryProduct("libspacetime", :libspacetime)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9")

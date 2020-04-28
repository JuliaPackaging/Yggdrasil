# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CovidSim"
version = v"0.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mrc-ide/covid-sim.git", "51959a733cbb856e4019031994deba2b1a7a9e4a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/covid-sim/

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/0001-fix-lib-cases.patch
fi

mkdir build && cd build/
# Build with GCC also for FreeBSD and macOS to use libgomp
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    ../src
make -j${nprocs}
mkdir -p "${bindir}"
cp "CovidSim${exeext}" "${bindir}/"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !isa(p, Windows)]


# The products that we will ensure are always built
products = [
    ExecutableProduct("CovidSim", :CovidSim)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

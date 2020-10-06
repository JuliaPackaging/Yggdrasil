# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HepMC3"
version = v"3.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://hepmc.web.cern.ch/hepmc/releases/HepMC3-3.2.2.tar.gz", "0e8cb4f78f804e38f7d29875db66f65e4c77896749d723548cc70fb7965e2d41")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/HepMC3-*/
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DHEPMC3_ENABLE_ROOTIO:BOOL=OFF -DHEPMC3_ENABLE_TEST:BOOL=ON -DHEPMC3_INSTALL_INTERFACES:BOOL=ON -DHEPMC3_ENABLE_PYTHON:BOOL=OFF -DHEPMC3_BUILD_STATIC_LIBS:BOOL=OFF -DHEPMC3_BUILD_DOCS:BOOL=OFF .. 
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:aarch64, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:powerpc64le, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:i686, libc=:musl, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:aarch64, libc=:musl, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64, compiler_abi=CompilerABI(cxxstring_abi=:cxx11))
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libHepMC3search", :libHepMC3search),
    LibraryProduct("libHepMC3", :libHepMC3)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")

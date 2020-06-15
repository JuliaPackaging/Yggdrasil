# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

name = "FastJet_Julia_Wrapper"
version = v"0.8.0"

# Collection of sources required to build FastJet_Julia_Wrapper
sources = [
	GitSource("https://github.com/jstrube/FastJet_Julia_Wrapper.git", "de21f03e874f91da2f3db5431603d172e2c004a6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/FastJet_Julia_Wrapper
mkdir build && cd build
cmake -DJulia_PREFIX=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
￼make install
install_license $WORKSPACE/srcdir/FastJet_Julia_Wrapper/FastJet_Julia_Wrapper/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11))
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libfastjetwrap", :libfastjetwrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll",version=v"0.8")),
    Dependency("FastJet_jll"),
    BuildDependency(PackageSpec(name="Julia_jll",version=v"1.4.1"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")

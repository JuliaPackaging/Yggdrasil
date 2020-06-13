# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIO_Julia_Wrapper"
version = v"0.8.2"

# Collection of sources required to build LCIOWrapBuilder
sources = [
	GitSource("https://github.com/jstrube/LCIO_Julia_Wrapper.git", "d3563a8b29086e264e9483c92a26b7d29faf7c70")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LCIO_Julia_Wrapper/
mkdir build && cd build
cmake -DJulia_PREFIX=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
install_license $WORKSPACE/srcdir/LCIO_Julia_Wrapper/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblciowrap", :lciowrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	Dependency("libcxxwrap_julia_jll"),
	Dependency("LCIO_jll"),
	BuildDependency("Julia_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")

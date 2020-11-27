# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

julia_version = v"1.5.3"

name = "LCIO_Julia_Wrapper"
version = v"0.13.0"

# Collection of sources required to build LCIOWrapBuilder
sources = [
	GitSource("https://github.com/jstrube/LCIO_Julia_Wrapper.git", "d0841c089dcb0a006a6f241a1716369760020e52")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/LCIO_Julia_Wrapper/
mkdir build && cd build
cmake -DJulia_PREFIX=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${libdir}/cmake -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
install_license $WORKSPACE/srcdir/LCIO_Julia_Wrapper/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = Platform[
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblciowrap", :lciowrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	Dependency(PackageSpec(name="libcxxwrap_julia_jll",version=v"0.8.5")),
    Dependency(PackageSpec(name="LCIO_jll", version=v"2.15.4")),
	BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"7", julia_compat = "^$(julia_version.major).$(julia_version.minor)")

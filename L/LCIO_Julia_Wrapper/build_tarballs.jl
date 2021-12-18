# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

name = "LCIO_Julia_Wrapper"
version = v"0.13.2"
julia_versions = [v"1.6", v"1.7", v"1.8"]

# Collection of sources required to build LCIOWrapBuilder
sources = [
	GitSource("https://github.com/jstrube/LCIO_Julia_Wrapper.git", "e28132bfdc0664faf9724a74b2ae33803c26dc5a")
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
include("../../L/libjulia/common.jl")

platforms = expand_cxxstring_abis(vcat(libjulia_platforms.(julia_versions)...))
filter!(!Sys.isfreebsd, platforms)
filter!(!Sys.iswindows, platforms)
filter!(p -> arch(p) ∉ ("armv6l", "armv7l") , platforms)
	
# The products that we will ensure are always built
products = [
    LibraryProduct("liblciowrap", :lciowrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll")),
    Dependency(PackageSpec(name="LCIO_jll")),
    BuildDependency(PackageSpec(name="libjulia_jll"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"8", julia_compat="1.6")

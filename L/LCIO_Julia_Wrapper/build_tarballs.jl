# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

include("../../L/libjulia/common.jl")
# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
using Pkg

name = "LCIO_Julia_Wrapper"
version = v"0.13.4"
julia_versions = filter(v -> v >= v"1.10", julia_versions)

# Collection of sources required to build LCIOWrapBuilder
sources = [
	GitSource("https://github.com/JuliaHEP/LCIO_Julia_Wrapper.git", "7a526aefd572575a881519e44eda8701a87e749d")
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
filter!(p -> arch(p) ∉ ("armv6l", "armv7l", "i686") , platforms)
filter!(p -> libc(p) != "musl" , platforms)
	
# The products that we will ensure are always built
products = [
    LibraryProduct("liblciowrap", :lciowrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll"), compat="0.14.3"),
    Dependency(PackageSpec(name="LCIO_jll"), compat="2.22.6"),
    BuildDependency(PackageSpec(name="libjulia_jll"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"8", julia_compat="1.10")

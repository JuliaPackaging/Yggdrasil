# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

julia_version = v"1.5.3"

name = "FastJet_Julia_Wrapper"
version = v"0.8.5"

# Collection of sources required to build FastJet_Julia_Wrapper
sources = [
	GitSource("https://github.com/jstrube/FastJet_Julia_Wrapper.git", "3fab5f91e88f2b348ec700c27733e0fcc661bd13"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/FastJet_Julia_Wrapper
mkdir build && cd build
cmake -DJulia_PREFIX=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
install_license $WORKSPACE/srcdir/FastJet_Julia_Wrapper/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# skip i686 musl builds (not supported by libjulia_jll)
filter!(p -> !(Sys.islinux(p) && libc(p) == "musl" && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfastjetwrap", :libfastjetwrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libcxxwrap_julia_jll",version=v"0.8.5")),
    Dependency("FastJet_jll"),
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"8", julia_compat = "^$(julia_version.major).$(julia_version.minor)")

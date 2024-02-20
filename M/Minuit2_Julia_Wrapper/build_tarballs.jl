using BinaryBuilder
using Pkg

sources = [
	GitSource("https://github.com/jstrube/Minuit2_Julia_Wrapper.git", "10bf344912baa777a940862d6d80631bea34a448")
]

julia_version = v"1.5.3"

name = "Minuit2_Julia_Wrapper"
version = v"0.1"

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Minuit2_Julia_Wrapper/
mkdir build && cd build
cmake -DJulia_PREFIX=${prefix} -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_FIND_ROOT_PATH=${prefix} ..
VERBOSE=ON cmake --build . --config Release --target install
install_license $WORKSPACE/srcdir/Minuit2_Julia_Wrapper/LICENSE 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
# filter!(!Sys.isfreebsd, platforms)
# filter!(!Sys.iswindows, platforms)
# filter!(p -> arch(p) != "armv7l", platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libminuit2wrap", :minuit2wrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
        Dependency(PackageSpec(name="libcxxwrap_julia_jll")),
        Dependency(PackageSpec(name="Minuit2_jll")),
        BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"8", julia_compat = "^$(julia_version.major).$(julia_version.minor)")

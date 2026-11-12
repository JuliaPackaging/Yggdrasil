# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "VNNLIB"
version = v"0.1.0"

# Collection of sources required to build
sources = [
    GitSource("https://github.com/VNNLIB/VNNLIB-CPP",
                  "a162737045b6e5a8b75995b783ac491b305d0679")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/VNNLIB-CPP/

mkdir build
cd build
cmake ..  -DCMAKE_BUILD_TYPE=Release -DMAKE_JULIA=ON -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DJulia_INCLUDE_DIRS="${prefix}/include/julia" -DBISON_EXECUTABLE=$(which bison) -DFLEX_EXECUTABLE=$(which flex) -DNO_BNFC=ON
make
cp ../bin/* $libdir
install_license $WORKSPACE/srcdir/VNNLIB-CPP/LICENSE
"""

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("VNNLibJulia", :libVNNLibJulia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat="0.14.7"),
    Dependency("libjulia_jll"; compat="1.11"),
    Dependency("CompilerSupportLibraries_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("flex_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"13", julia_compat="1.10")
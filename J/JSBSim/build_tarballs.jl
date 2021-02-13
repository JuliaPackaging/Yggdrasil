using BinaryBuilder

name = "JSBSim"
version = v"1.1.6"
julia_version = v"1.5.3"

# Collection of sources required to build JSBSim
sources = [
    GitSource("https://github.com/bcoconni/jsbsim.git",
              "a31ecb8727361aa74dee4ea7158c944848f78fb6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jsbsim
mkdir build && cd build
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-DCMAKE_CXXFLAGS_RELEASE="-D_POSIX_C_SOURCE")
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DOCS=OFF \
    -DBUILD_PYTHON_MODULE=OFF \
    -DBUILD_JULIA_PACKAGE=ON \
    -DJulia_PREFIX="$prefix" \
    "${FLAGS[@]}" \
    ..
make -j${nproc}
cp julia/*JSBSimJL* $prefix/.
cp ../julia/JSBSim.jl $prefix/.
"""

ARGS
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    FileProduct("JSBSim.jl", :JSBSim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    Dependency("libcxxwrap_julia_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")

using BinaryBuilder

name = "JSBSim"
version = v"1.1.5"
julia_version = v"1.5.3"

# Collection of sources required to build JSBSim
sources = [
    GitSource("https://github.com/bcoconni/jsbsim.git",
              "d528f8b38effb54ee035b572ee1beebdea7d2eb8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jsbsim
mkdir build && cd build
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-DCMAKE_CXX_FLAGS_RELEASE="-D_POSIX_C_SOURCE")
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DOCS=OFF \
    -DBUILD_PYTHON_MODULE=OFF \
    -DBUILD_JULIA_PACKAGE=ON \
    -DJulia_PREFIX=${prefix} \
    "${FLAGS[@]}" \
    ..
cmake --build . --target JSBSimJL -- -j${nproc}
install_license $WORKSPACE/srcdir/jsbsim/COPYING
cp julia/*JSBSimJL*.$dlext $libdir/.
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
platforms = expand_cxxstring_abis(platforms)

filter!(p -> libc(p) != "musl" && !Sys.isfreebsd(p), platforms) # muslc is not supported

# The products that we will ensure are always built
products = [
    LibraryProduct("libJSBSimJL", :JSBSim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    Dependency("libcxxwrap_julia_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8",
    julia_compat = "$(julia_version.major).$(julia_version.minor)")

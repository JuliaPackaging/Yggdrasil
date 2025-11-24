# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LEMON"
version = v"1.3.3"
upstreamversion = v"1.3.1"
min_jl_version = v"1.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://web.archive.org/web/20240805201231if_/http://lemon.cs.elte.hu/pub/sources/lemon-$(upstreamversion).tar.gz", "71b7c725f4c0b4a8ccb92eb87b208701586cf7a96156ebd821ca3ed855bad3c8")
    DirectorySource("./bundled") # for the Julia wrapper
]

# Bash recipe for building across all platforms
script = raw"""
export CXXFLAGS="${CXXFLAGS} -Wno-register" # cland C++17 expects the `register` storage class to be written as `REGISTER`

# build LEMON
cd $WORKSPACE/srcdir/lemon-*/
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE

cd ..

# build the CxxWrap.jl wrapper that we bundle
# I guess the LEMON devs were funny and decided to call some of their build products emon so that the gcc flag is -lemon instead of -llemon (but not on windows)
if [[ "${target}" == *mingw* ]]; then
    LIBLEMON=lemon
else
    LIBLEMON=emon
fi
$CXX -shared -std=c++17 -O3 -fPIC -o ${libdir}/liblemoncxxwrap.${dlext} cxxwrap/lemoncxxwrap.cpp -I$includedir/julia -L${libdir} -l${LIBLEMON} -ljulia -lcxxwrap_julia
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

# Because we bundle the Julia-targetting cxxwrapper,
# we need a build for each supported julia version.
include("../../L/libjulia/common.jl")
supported_julia_versions = filter(>=(min_jl_version), julia_versions)
platforms = vcat(libjulia_platforms.(supported_julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dimacs-to-lgf", :dimacs_to_lgf),
    ExecutableProduct("lgf-gen", :lgf_gen),
    ExecutableProduct("dimacs-solver", :dimacs_solver),
    LibraryProduct("liblemoncxxwrap", :liblemoncxxwrap)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat = "~0.14.4"),
    BuildDependency("libjulia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat=string(min_jl_version), preferred_gcc_version = v"7.1.0")


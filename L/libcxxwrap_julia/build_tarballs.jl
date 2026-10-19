# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "libcxxwrap_julia"
version = v"0.14.12"

git_repo = "https://github.com/JuliaInterop/libcxxwrap-julia.git"

# Collection of sources required to complete build
sources = [
    GitSource(git_repo, "970d35ef408e3aa378cb435b0a1aeaa44016334e"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir build
cd build

if [[ $target == *freebsd* ]]; then
    fbsdflag="-DCMAKE_CXX_FLAGS=-pthread"
fi

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release $fbsdflag \
    ../libcxxwrap-julia/
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/libcxxwrap-julia*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcxxwrap_julia", :libcxxwrap_julia; dlopen_flags=[:RTLD_GLOBAL]),
    LibraryProduct("libcxxwrap_julia_stl", :libcxxwrap_julia_stl; dlopen_flags=[:RTLD_GLOBAL]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version="1.11.4")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"10", julia_compat = libjulia_julia_compat(julia_versions))

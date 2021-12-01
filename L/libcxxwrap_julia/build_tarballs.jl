# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcxxwrap_julia"
version = v"0.8.8"

julia_versions = [v"1.6.0", v"1.7.0", v"1.8.0"]

is_yggdrasil = haskey(ENV, "BUILD_BUILDNUMBER")
git_repo = is_yggdrasil ? "https://github.com/JuliaInterop/libcxxwrap-julia.git" : joinpath(ENV["HOME"], "src/julia/libcxxwrap-julia/")
unpack_target = is_yggdrasil ? "" : "libcxxwrap-julia"

# Collection of sources required to complete build
sources = [
    GitSource(git_repo, "37743e11cda7363a17840fe2353ff78a7e964a2c", unpack_target=unpack_target),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir build
cd build

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ../libcxxwrap-julia/
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/libcxxwrap-julia*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcxxwrap_julia", :libcxxwrap_julia; dlopen_flags=[:RTLD_GLOBAL]),
    LibraryProduct("libcxxwrap_julia_stl", :libcxxwrap_julia_stl; dlopen_flags=[:RTLD_GLOBAL]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"9", julia_compat = "1.6")

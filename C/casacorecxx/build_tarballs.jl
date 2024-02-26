# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "casacorecxx"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [GitSource("https://github.com/torrance/Casacore.jl.git", "bf73cbd1cf6c681102b8314172970dc1ca1618da")]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Casacore.jl/casacorecxx
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJulia_PREFIX=${prefix}\
    ..
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
exit
"""

# Julia version compatibility
julia_versions = [v"1.7", v"1.8", v"1.9", v"1.10"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

# Get a full list of platforms supported by Libjulia
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# Filter this list based on the same filter criteria used in the casacore build script
filter!(platforms) do p
    !Sys.iswindows(p) && !Sys.isfreebsd(p) && libc(p) != "musl"
end

# The products that we will ensure are always built
products = Product[LibraryProduct("libcasacorecxx", :libcasacorecxx),]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency("libcxxwrap_julia_jll"),
                Dependency("casacore_jll"),
                BuildDependency("libjulia_jll")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat,
               preferred_gcc_version=v"7") # We need C++17 for CxxWrap

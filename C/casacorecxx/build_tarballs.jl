# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Get a full list of platforms supported by Libjulia
include("../../L/libjulia/common.jl")
filter!(x -> v"1.10" <= x <= v"1.13", julia_versions)

name = "casacorecxx"
version = v"0.4.0"

# Collection of sources required to complete build
sources = [GitSource("https://github.com/JuliaAstro/Casacore.jl.git", "a3e775c203692352b99bf11eab755f618fb88017")]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Casacore.jl/casacorecxx
mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_CXX_STANDARD=17 \
    ..

VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
exit
"""

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# Filter this list based on the same filter criteria used in the casacore build script
filter!(platforms) do p
    arch(p) != "riscv64" && !Sys.iswindows(p) && !Sys.isfreebsd(p) && libc(p) != "musl"
end

# The products that we will ensure are always built
products = Product[LibraryProduct("libcasacorecxx", :libcasacorecxx),]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency("libcxxwrap_julia_jll", compat = "0.14.4"),
                Dependency("casacore_jll", compat="3.7.1"),
                BuildDependency(PackageSpec(;name="libjulia_jll", version="1.11.0"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10",
               preferred_gcc_version=v"8") # We need C++17 for CxxWrap

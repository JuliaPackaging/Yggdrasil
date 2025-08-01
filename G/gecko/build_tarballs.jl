# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# The version of this JLL is decoupled from the upstream version.
name = "gecko"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/LLNL/gecko.git", "490ab7d9b7b4e0f007e10d2af2b022b96d427fee"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# First build the gecko library
cd $WORKSPACE/srcdir/gecko/
mkdir build
cmake -S ./ -B build .. \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build

# Now with the gecko library we can build the wrapper
cd $WORKSPACE/srcdir/geckowrapper/
mkdir build
cmake -S ./ -B build .. \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DJulia_PREFIX=${prefix} \
    -DGECKO_DIR=$prefix \
    -DGECKO_LIBRARY="-lgecko" \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Only support Linux and FreeBSD
include("../../L/libjulia/common.jl")
platforms = reduce(vcat, libjulia_platforms.(julia_versions))
# platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> (Sys.islinux(p) || Sys.isfreebsd(p)), platforms)
# filter!(p -> v"1.11" ≤ VersionNumber(p["julia_version"]), platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libgecko", :libgecko)
    LibraryProduct("libgeckowrapper", :libgeckowrapper)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"; compat="0.14.2"),
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", julia_compat="1.6")

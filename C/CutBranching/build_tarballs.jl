# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CutBranching"
version = v"0.1.1"

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/claud10cv/CutBranching.git", "727975876b918ff71bae2c71442b2564cfaf2081")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CutBranching/
Julia_PREFIX=${prefix}
cmake -B build \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DJulia_PREFIX=${Julia_PREFIX} \
-DJlCxx_DIR=$prefix/lib/cmake/JlCxx
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl") 
platforms = vcat(libjulia_platforms.(julia_versions)...) 
platforms = expand_cxxstring_abis(platforms)
filter!(x -> libc(x) != "musl", platforms)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmiscb", "miscblib"], :miscb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	Dependency("libcxxwrap_julia_jll"; compat = "~0.12.2"),
	BuildDependency(PackageSpec(; name = "libjulia_jll", version = v"1.10.9"))
	
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")

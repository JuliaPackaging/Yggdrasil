# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CutBranching"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/claud10cv/CutBranching.git", "46c14849e75e647045eac97764d31815d9a2f9d2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CutBranching/
Julia_PREFIX=${prefix}
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DJulia_PREFIX=${Julia_PREFIX} -DJlCxx_DIR=$prefix/lib/cmake/JlCxx
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(x -> libc(x) != "musl", platforms)
filter!(x -> os(x) != "windows", platforms)
#platforms = [
#    Platform("x86_64", "linux"; libc = "glibc"),
#]


# The products that we will ensure are always built
products = Product[
	LibraryProduct(["libmiscb", "miscblib"], :miscb)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
	Dependency("libcxxwrap_julia_jll"),
	Dependency("libjulia_jll")
	
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")

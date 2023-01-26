# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TMscore"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cossio/TMscore.git", "3b7d30405c94df0eb55fe2510255145616a4bb46")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TMscore/
mkdir -p ${bindir}
${CXX} -O3 -lm -o ${bindir}/TMscore${exeext} TMscore.cpp
install_license LICENSE_1_0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("TMscore", :TMscore)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

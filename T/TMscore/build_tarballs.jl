# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TMscore"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    FileSource("https://seq2fun.dcmb.med.umich.edu//TM-score/TMscore.cpp", "30274251f4123601af102cf6d4f1a9cc496878c1ae776702f554e2fc25658d7f"),
    FileSource("https://www.boost.org/LICENSE_1_0.txt", "c9bff75738922193e67fa726fa225535870d2aa1059f91452c411736284ad566")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
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
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

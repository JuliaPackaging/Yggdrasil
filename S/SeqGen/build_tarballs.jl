# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SeqGen"
version = v"1.3.4"

# Collection of sources required to build SFML
sources = [
    GitSource("https://github.com/rambaut/Seq-Gen.git", "bc9d8070b2cd1f1352f74282e5b209302eae38a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Seq-Gen/source
head -39 seq-gen.c > license
install_license ${WORKSPACE}/srcdir/Seq-Gen/source/license

# compile seq-gen
make -j${nproc}

# move to bindir
install -Dvm 755 "seq-gen" "${bindir}/seq-gen${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("seq-gen", :seqgen),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

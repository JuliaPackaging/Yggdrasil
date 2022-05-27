# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "LinearFold"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/LinearFold/LinearFold/archive/refs/tags/v$(version.major).$(version.minor).tar.gz",
                  "2ae56b5f183472c2de96782e770a91e57f82e0ab511dfc0d9d612aa4e6155f60"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LinearFold-*/

make -j${nproc}
mkdir -p ${bindir}
for prg in linearfold_c linearfold_v; do
    cp bin/$prg ${bindir}/${prg}${exeext}
done

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("linearfold_c", :linearfold_c),
    ExecutableProduct("linearfold_v", :linearfold_v),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

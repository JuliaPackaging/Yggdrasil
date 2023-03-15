# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LinearPartition"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/LinearFold/LinearPartition/archive/refs/tags/v$(version.major).$(version.minor).tar.gz",
                  "4fdea96f7ffbd4804d9308ddb46db5f96d1abc4b7bd737725f9bedcae3c88178"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LinearPartition-*/

make -j${nproc} CC=${CXX}
mkdir -p ${bindir}
for prg in linearpartition_{c,v}; do
    install -Dvm 755 "bin/${prg}" "${bindir}/${prg}${exeext}"
done

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("linearpartition_c", :linearpartition_c),
    ExecutableProduct("linearpartition_v", :linearpartition_v),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

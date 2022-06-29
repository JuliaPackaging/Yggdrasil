# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LinearSampling"
# invented version number because there aren't any releases yet and we
# are installing from a git commit
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/LinearFold/LinearSampling/archive/ebaf5be2854790170402c5a97f8c954313a33ac4.tar.gz",
                  "d3d82513ff848a2d8ad7eb1a6ceef81c5a071b324d8db2cecc0363536e3d2e4a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LinearSampling-*/

make -j${nproc} CC=${CXX}
mkdir -p ${bindir}
for b in bin/*; do
    install -Dvm 755 "${b}" "${bindir}/$(basename "${b}")${exeext}"
done

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("exact_linearsampling_lazysaving", :exact_linearsampling_lazysaving),
    ExecutableProduct("exact_linearsampling_nonsaving", :exact_linearsampling_nonsaving),
    ExecutableProduct("linearsampling_lazysaving", :linearsampling_lazysaving),
    ExecutableProduct("linearsampling_nonsaving", :linearsampling_nonsaving),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

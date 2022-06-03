# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LinearTurboFold"
# invented version number because there aren't any releases yet and we
# are installing from a git commit
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/LinearFold/LinearTurboFold/archive/3e58e713e2743ec57aad21d557289c43571e97f0.tar.gz",
                  "58b02b83cb71675af92a14b18a0bf64a1171e554cfaa5e914038d97c6589fd30"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LinearTurboFold-*/

make -j${nproc} CC=${CXX}
mkdir -p ${bindir}
for b in bin/*; do
    install -Dvm 755 "${b}" "${bindir}/$(basename "${b}")${exeext}"
done

# needed parameter files
install -Dvm 755 src/data_tables/fam_hmm_pars.dat "${prefix}/share/LinearTurboFold/src/data_tables/fam_hmm_pars.dat"

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("linearturbofold", :linearturbofold),
    FileProduct("share/LinearTurboFold/src/data_tables/fam_hmm_pars.dat", :fam_hmm_pars),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

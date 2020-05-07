# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FastJet"
version = v"3.3.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://fastjet.fr/repo/fastjet-3.3.4.tar.gz", "432b51401e1335697c9248519ce3737809808fc1f6d1644bfae948716dddfc03"),
    ArchiveSource("http://fastjet.hepforge.org/contrib/downloads/fjcontrib-1.044.tar.gz", "de3f45c2c1bed6d7567483e4a774575a504de8ddc214678bac7f64e9d2e7e7a7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fastjet-*/
export CXXFLAGS="-O3 -Wall"
export CFLAGS="-O3 -Wall"
if [[ "${target}" == *-freebsd* ]]; then
    # Needed to fix the following errors
    #   undefined reference to `backtrace_symbols'
    #   undefined reference to `backtrace'
    export LDFLAGS="-lexecinfo"
fi
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    # This is needed in order to build the shared library on Windows when we get
    #   libtool: warning: undefined symbols not allowed in x86_64-w64-mingw32 shared libraries; building static only
    FLAGS+=(LDFLAGS="-no-undefined")
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-auto-ptr
make -j ${nprocs} "${FLAGS[@]}"
make install
tail -n 340 COPYING > LICENSE
install_license LICENSE

cd $WORKSPACE/srcdir/fjcontrib-*/
for name in ClusteringVetoPlugin ConstituentSubtractor EnergyCorrelator FlavorCone GenericSubtractor JetCleanser JetFFMoments JetsWithoutJets LundPlane Nsubjettiness QCDAwarePlugin RecursiveTools ScJet SoftKiller SubjetCounting ValenciaPlugin VariableR
do
    cd $name
    rm example*
    c++ -fPIC -shared -I${includedir} -O3 -Wall ${LDFLAGS} [A-Z]*.cc -o "${libdir}/lib${name}.${dlext}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libConstituentSubtractor", :libClusteringVetoPlugin),
    LibraryProduct("libQCDAwarePlugin", :libQCDAwarePlugin),
    LibraryProduct("libJetFFMoments", :libJetFFMoments),
    LibraryProduct("libLundPlane", :libLundPlane),
    LibraryProduct("libJetsWithoutJets", :libJetsWithoutJets),
    LibraryProduct("libEnergyCorrelator", :libEnergyCorrelator),
    LibraryProduct("libfastjettools", :libfastjettools),
    LibraryProduct("libSoftKiller", :libSoftKiller),
    LibraryProduct("libRecursiveTools", :libRecursiveTools),
    LibraryProduct("libfastjet", :libfastjet),
    LibraryProduct("libValenciaPlugin", :libValenciaPlugin),
    LibraryProduct("libsiscone", :libsiscone),
    LibraryProduct("libNsubjettiness", :libNsubjettiness),
    LibraryProduct("libfastjetplugins", :libfastjetplugins),
    LibraryProduct("libVariableR", :libVariableR),
    LibraryProduct("libsiscone_spherical", :libsiscone_spherical),
    LibraryProduct("libJetCleanser", :libJetCleanser),
    LibraryProduct("libFlavorCone", :libFlavorCone),
    LibraryProduct("libGenericSubtractor", :libGenericSubtractor),
    LibraryProduct("libScJet", :libScJet),
    LibraryProduct("libSubjetCounting", :libSubjetCounting),
    LibraryProduct("libClusteringVetoPlugin", :libClusteringVetoPlugin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

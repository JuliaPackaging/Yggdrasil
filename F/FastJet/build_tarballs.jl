# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FastJet"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://fastjet.fr/repo/fastjet-3.4.0.tar.gz", "ee07c8747c8ead86d88de4a9e4e8d1e9e7d7614973f5631ba8297f7a02478b91"),
    ArchiveSource("http://fastjet.hepforge.org/contrib/downloads/fjcontrib-1.048.tar.gz", "f9989d3b6aeb22848bcf91095c30607f027d3ef277a4f0f704a8f0fc2e766981")
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
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-auto-ptr --disable-static
make -j ${nprocs} "${FLAGS[@]}"
make install
tail -n 340 COPYING > LICENSE
install_license LICENSE
cp include/fastjet/config_win.h ${includedir}/fastjet/

cd $WORKSPACE/srcdir/fjcontrib-*/
for name in ClusteringVetoPlugin ConstituentSubtractor EnergyCorrelator FlavorCone GenericSubtractor JetCleanser JetFFMoments JetsWithoutJets LundPlane Nsubjettiness QCDAwarePlugin RecursiveTools ScJet SoftKiller SubjetCounting ValenciaPlugin VariableR
do
    cd $name
    rm example*
    c++ -fPIC -shared -I${includedir} -O3 -Wall ${LDFLAGS} [A-Z]*.cc -o "${libdir}/lib${name}.${dlext}" -lfastjet -lfastjettools
    cp [A-Z]*.hh ${includedir}/fastjet
    cd ..
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libConstituentSubtractor", :libConstituentSubtractor),
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
    LibraryProduct("libClusteringVetoPlugin", :libClusteringVetoPlugin),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")

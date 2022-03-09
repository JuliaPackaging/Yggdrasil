# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAFFT"
version = v"7.490"

# Notes
# - build fails on windows, include file sys/resource.h is missing

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mafft.cbrc.jp/alignment/software/mafft-$(version.major).$(version.minor)-with-extensions-src.tgz", "d6eef33d8b9e282e20f9b25b6b6fb2757b9b6900e397ca621d56da86d9976541")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mafft-*/

# The mafft shell script is generated from mafft.tmpl. Change the
# absolute path hardcoded at build-time to a relative path generated
# at run-time.
sed -i -e 's|prefix=_LIBDIR|prefix="$(dirname "$(realpath "$0")")/../libexec/mafft"|' core/mafft.tmpl

cd core
make CC=${CC} CXX=${CXX} PREFIX=${prefix}
cd ..

cd extensions
make CC=${CC} CXX=${CXX} PREFIX=${prefix}
cd ..

cd core
make CC=${CC} CXX=${CXX} PREFIX=${prefix} install
cd ..

cd extensions
make CC=${CC} CXX=${CXX} PREFIX=${prefix} install
cd ..

install_license license
mv extensions/mxscarna_src/README extensions/mxscarna_src/README-mxscarna
mv extensions/mxscarna_src/probconsRNA/README extensions/mxscarna_src/probconsRNA/README-probcons
mv extensions/mxscarna_src/vienna/COPYING extensions/mxscarna_src/vienna/COPYING-ViennaRNA
install_license extensions/mxscarna_src/README-mxscarna
install_license extensions/mxscarna_src/probconsRNA/README-probcons
install_license extensions/mxscarna_src/vienna/COPYING-ViennaRNA
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true, exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("einsi", :einsi),
    ExecutableProduct("fftns", :fftns),
    ExecutableProduct("fftnsi", :fftnsi),
    ExecutableProduct("ginsi", :ginsi),
    ExecutableProduct("linsi", :linsi),
    ExecutableProduct("mafft", :mafft),
    ExecutableProduct("mafft-distance", :mafft_distance),
    ExecutableProduct("mafft-einsi", :mafft_einsi),
    ExecutableProduct("mafft-fftns", :mafft_fftns),
    ExecutableProduct("mafft-fftnsi", :mafft_fftnsi),
    ExecutableProduct("mafft-ginsi", :mafft_ginsi),
    ExecutableProduct("mafft-homologs.rb", :mafft_homologs_rb),
    ExecutableProduct("mafft-linsi", :mafft_linsi),
    ExecutableProduct("mafft-nwns", :mafft_nwns),
    ExecutableProduct("mafft-nwnsi", :mafft_nwnsi),
    ExecutableProduct("mafft-profile", :mafft_profile),
    ExecutableProduct("mafft-qinsi", :mafft_qinsi),
    ExecutableProduct("mafft-sparsecore.rb", :mafft_sparsecore_rb),
    ExecutableProduct("mafft-xinsi", :mafft_xinsi),
    ExecutableProduct("nwns", :nwns),
    ExecutableProduct("nwnsi", :nwnsi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

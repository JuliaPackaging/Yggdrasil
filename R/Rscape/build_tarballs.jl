# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Rscape"
upstream_version = "2.0.0.p"
version = VersionNumber(replace(upstream_version, r"([0-9]+\.[0-9]+\.[0-9]+).*" => s"\1"))

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://rivaslab.org/software/rscape/rscape_v$(upstream_version).tar.gz",
                  "e70f8b1a389c3c29888cba2f99034ede53d3c6aa3f798ce3e467935b267e59cc"),
    DirectorySource("./bundled")
]

# TODO
# - R-scape complains about missing gnuplot at runtime, probably
#   needed for some plots, but works nonetheless

# Bash recipe for building across all platforms
# Notes
# - configure mentions --with-gsl, but the build fails with linking
#   errors using this option (probably -lgsl is missing). Neither this
#   configure option nor GSL are mentioned in the manual, so hopefully
#   GSL isn't needed. I think the flag comes from HMMER, but it seems
#   like the functions that are used from HMMER don't need GSL.
script = raw"""
cd $WORKSPACE/srcdir/rscape*/

# allow using the RSCAPE_HOME, RSCAPE_BIN, RSCAPE_SHARE environment
# variables to override default directories for finding data params at
# runtime instead of a hardcoded path (which doesn't work because that
# is set to the srcdir during build)
atomic_patch -p1 ../patches/allow-env-var-override-of-dirs.patch

update_configure_scripts
./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target}

make -j${nproc}
make install

# install data params
for f in data/power/*; do
    install -Dvm 755 "${f}" "${prefix}/${f}"
done

cp ./lib/R2R/R2R-current/r2r-license-text.txt r2r-license-text.txt
cp ./lib/R2R/R2R-current/NotByZasha/nlopt-*/src/algs/direct/COPYING COPYING-nlopt-direct
cp ./lib/R2R/R2R-current/NotByZasha/nlopt-*/COPYING COPYING-nlopt
cp ./lib/hmmer/libdivsufsort/COPYING COPYING-libdivsufsort
cp ./lib/hmmer/easel/LICENSE LICENSE-easel
cp ./lib/hmmer/LICENSE LICENSE-hmmer
cp ./lib/infernal/infernal-current/LICENSE LICENSE-infernal

# Note: Rscape manual says it is GPLv3, LICENSE says it is BSD
echo \"""
The R-scape manual (documentation/R-scape_userguide.pdf) says it is
licensed under GPLv3:

R-scape is licensed and freely distributed under the GNU General
Public License version 3 (GPLv3). For a copy of the License, see
http://www.gnu.org/licenses/.
\""" > LICENSE-Rscape-note-GPLv3

# Note: license file for R-view is missing, it claims to be GPLv3 but
#       doesn't contain a full copy of the license.
echo \"""
The source code for R-view doesn't include a license file, and the only note in the
source code is in lib/R-view/src/rview_config.h which says it is GPLv3.
This gets printed as a banner when running the R-view program. The banner is:

# R-view :: R-view - basepairs(RNA) and contacts(RNA/peptides) from a pdb file
# R-view 0.1 (August 2018)
# Copyright (C) 2018 Howard Hughes Medical Institute.
# Freely distributed under the GNU General Public License (GPLv3).
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
\""" > R-view-banner

# Note: license for FastTree only found in source code
head -n 42 lib/FastTree/src/FastTree.c > LICENSE-FastTree

# Note: no license for rnaview given in tarball
echo \"""
No explicit license in the lib/RNAVIEW directory.

In the Gentoo package repositories it is listed as public-domain:

https://packages.gentoo.org/packages/sci-biology/rnaview
\""" > LICENSE-rnaview

install_license LICENSE
install_license LICENSE-Rscape-note-GPLv3
install_license r2r-license-text.txt
install_license COPYING-nlopt-direct
install_license COPYING-nlopt
install_license COPYING-libdivsufsort
install_license LICENSE-easel
install_license LICENSE-hmmer
install_license LICENSE-infernal
install_license R-view-banner
install_license LICENSE-FastTree
install_license LICENSE-rnaview
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Notes:
# - configure demands either sse (i686/x86_64) or vmx (powerpc) vector
#   instructions (this comes from HMMER)
# - windows compile fails (see HMMER build, but here also in the lib/R2R subdir)
# - compile fails on powerpc64le:
#   "HMMER3 Altivec/VMX only supports bigendian platforms: e.g. ppc64 not ppc64le"
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || proc_family(p) != "intel")
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("appcov", :appcov),
    ExecutableProduct("esl-afetch", :esl_afetch),
    ExecutableProduct("esl-reformat", :esl_reformat),
    ExecutableProduct("FastTree", :FastTree),
    ExecutableProduct("msafilter", :msafilter),
    ExecutableProduct("r2r", :r2r),
    ExecutableProduct("rnaview", :rnaview),
    ExecutableProduct("R-scape", :R_scape),
    ExecutableProduct("R-scape-sim", :R_scape_sim),
    ExecutableProduct("R-scape-sim-nobps", :R_scape_sim_nobps),
    ExecutableProduct("R-view", :R_view),
    # perl scripts
    FileProduct("bin/pdb_parse.pl", :pdb_parse_pl),
    FileProduct("bin/r2r_msa_comply.pl", :r2r_msa_comply_pl),
    FileProduct("bin/SelectSubFamilyFromStockholm.pl", :SelectSubFamilyFromStockholm_pl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

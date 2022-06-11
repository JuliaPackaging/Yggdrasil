# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Infernal"
version = v"1.1.4"

easel_version = v"0.48"
hmmer_version = v"3.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/EddyRivasLab/infernal/archive/refs/tags/infernal-$(version).tar.gz",
                  "311163c0a21a216e90862df81cd6c13811032076535e44fed4eabdcf45093fea"),
    ArchiveSource("https://github.com/EddyRivasLab/easel/archive/refs/tags/easel-$(easel_version.major).$(easel_version.minor).tar.gz",
                  "c5d055acbe88fa834e81424a15fc5fa54ac787e35f2ea72d4ffd9ea2c1aa29cf"),
    ArchiveSource("https://github.com/EddyRivasLab/hmmer/archive/refs/tags/hmmer-$(hmmer_version).tar.gz",
                  "fab109c67fb8077b32f7907bf07efbc071147be0670aee757c9a3ca7e2d485be")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/infernal-*/

mv ../easel-*/ easel
mv ../hmmer-*/ hmmer

# Update the config.sub from infernal.  Otherwise we get an error when running
# configure: "Invalid configuration `x86_64-linux-musl'."
update_configure_scripts

# generate configure script
autoreconf -vi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-pic --enable-threads --with-gsl

make -j${nproc}
make install

cd easel && make install
mv LICENSE LICENSE.easel

install_license LICENSE.easel
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Notes
# - Infernal requires SSE or VMX vector instructions,
#   VMX only on big-endian platforms (ppc64 not ppc64le)
# - ARM vector instruction support coming soon
# - build fails on windows
#   easel.c:39:20: fatal error: syslog.h: No such file or directory
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || proc_family(p) != "intel")

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmalign", :cmalign),
    ExecutableProduct("cmbuild", :cmbuild),
    ExecutableProduct("cmcalibrate", :cmcalibrate),
    ExecutableProduct("cmconvert", :cmconvert),
    ExecutableProduct("cmemit", :cmemit),
    ExecutableProduct("cmfetch", :cmfetch),
    ExecutableProduct("cmpress", :cmpress),
    ExecutableProduct("cmscan", :cmscan),
    ExecutableProduct("cmsearch", :cmsearch),
    ExecutableProduct("cmstat", :cmstat),
    ExecutableProduct("easel", :easel),
    ExecutableProduct("esl-afetch", :esl_afetch),
    ExecutableProduct("esl-alimanip", :esl_alimanip),
    ExecutableProduct("esl-alimap", :esl_alimap),
    ExecutableProduct("esl-alimask", :esl_alimask),
    ExecutableProduct("esl-alimerge", :esl_alimerge),
    ExecutableProduct("esl-alipid", :esl_alipid),
    ExecutableProduct("esl-alirev", :esl_alirev),
    ExecutableProduct("esl-alistat", :esl_alistat),
    ExecutableProduct("esl-compalign", :esl_compalign),
    ExecutableProduct("esl-compstruct", :esl_compstruct),
    ExecutableProduct("esl-construct", :esl_construct),
    ExecutableProduct("esl-histplot", :esl_histplot),
    ExecutableProduct("esl-mask", :esl_mask),
    ExecutableProduct("esl-mixdchlet", :esl_mixdchlet),
    ExecutableProduct("esl-reformat", :esl_reformat),
    ExecutableProduct("esl-selectn", :esl_selectn),
    ExecutableProduct("esl-seqrange", :esl_seqrange),
    ExecutableProduct("esl-seqstat", :esl_seqstat),
    ExecutableProduct("esl-sfetch", :esl_sfetch),
    ExecutableProduct("esl-shuffle", :esl_shuffle),
    ExecutableProduct("esl-ssdraw", :esl_ssdraw),
    ExecutableProduct("esl-translate", :esl_translate),
    ExecutableProduct("esl-weight", :esl_weight),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

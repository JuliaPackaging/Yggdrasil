# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "HMMER"
version_string = "3.4"
version = let ver = VersionNumber(version_string)
    VersionNumber(ver.major, ver.minor, ver.patch)
end

# url = "http://eddylab.org/software/hmmer/"
# description = "HMMER: biological sequence analysis using profile HMMs"

sources = [
    ArchiveSource("http://eddylab.org/software/hmmer/hmmer-$(version_string).tar.gz",
                  "ca70d94fd0cf271bd7063423aabb116d42de533117343a9b27a65c17ff06fbf3")
]

# TODO
# - support MPI

# Notes:
# - configure demands either sse (i686/x86_64) or vmx (powerpc), or
#   neon (ARM) vector instructions
# - windows compile fails, can't find syslog.h
# - compile fails on powerpc64le:
#   "HMMER3 Altivec/VMX only supports bigendian platforms: e.g. ppc64 not ppc64le"

script = raw"""
cd $WORKSPACE/srcdir/hmmer-*/

EXTRA_CFG=
if [[ "${proc_family}" == "intel" ]]; then
    EXTRA_CFG="${EXTRA_CFG} --enable-sse"
elif [[ "${proc_family}" == "arm" ]]; then
    EXTRA_CFG="${EXTRA_CFG} --enable-neon"
fi

export CPPFLAGS="-I${includedir}"
update_configure_scripts

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-gsl --enable-pic --enable-threads ${EXTRA_CFG}
make -j${nproc}
make install

cd easel && make install
mv LICENSE LICENSE.easel

install_license LICENSE.easel
install_license ../LICENSE
"""

platforms = supported_platforms(
    exclude = p -> Sys.iswindows(p) || (proc_family(p) != "intel" && proc_family(p) != "arm") || p == Platform("aarch64", "freebsd")
)

products = [
    ExecutableProduct("alimask", :alimask),
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
    ExecutableProduct("hmmalign", :hmmalign),
    ExecutableProduct("hmmbuild", :hmmbuild),
    ExecutableProduct("hmmconvert", :hmmconvert),
    ExecutableProduct("hmmemit", :hmmemit),
    ExecutableProduct("hmmfetch", :hmmfetch),
    ExecutableProduct("hmmlogo", :hmmlogo),
    ExecutableProduct("hmmpgmd", :hmmpgmd),
    ExecutableProduct("hmmpgmd_shard", :hmmpgmd_shard),
    ExecutableProduct("hmmpress", :hmmpress),
    ExecutableProduct("hmmscan", :hmmscan),
    ExecutableProduct("hmmsearch", :hmmsearch),
    ExecutableProduct("hmmsim", :hmmsim),
    ExecutableProduct("hmmstat", :hmmstat),
    ExecutableProduct("jackhmmer", :jackhmmer),
    ExecutableProduct("makehmmerdb", :makehmmerdb),
    ExecutableProduct("nhmmer", :nhmmer),
    ExecutableProduct("nhmmscan", :nhmmscan),
    ExecutableProduct("phmmer", :phmmer),
]

dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="2.7.2")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

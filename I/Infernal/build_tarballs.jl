using BinaryBuilder, BinaryBuilderBase, Pkg

name = "Infernal"
version = v"1.1.5"

sources = [
    ArchiveSource("http://eddylab.org/infernal/infernal-$(version).tar.gz",
                  "ad4ddae02f924ca7c85bc8c4a79c9f875af8df96aeb726702fa985cbe752497f"),
    DirectorySource("./bundled")
]

script = raw"""
cd $WORKSPACE/srcdir/infernal-*/

atomic_patch -p1 ../patches/rmark-missing-gsl-link.patch

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

# Notes
# - Infernal requires SSE, VMX or NEON vector instructions,
#   VMX only works on big-endian platforms (ppc64 not ppc64le)
# - build fails on windows
#   easel.c:39:20: fatal error: syslog.h: No such file or directory
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || proc_family(p) ∉ ("intel", "arm"))

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

dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

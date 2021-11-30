# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "HMMER"
version = v"3.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://eddylab.org/software/hmmer/hmmer-$(version).tar.gz",
                  "92fee9b5efe37a5276352d3502775e7c46e9f7a0ee45a331eacb2a0cac713c69")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hmmer-*/

export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-gsl --enable-threads --enable-sse
make -j${nproc}
make install

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#
# Notes:
# - configure demands either sse (i686/x86_64) or vmx (powerpc) vector
#   instructions
# - windows compile fails, can't find syslog.h
# - compile fails on powerpc64le:
#   "HMMER3 Altivec/VMX only supports bigendian platforms: e.g. ppc64 not ppc64le"
platforms = supported_platforms(; exclude = p -> Sys.iswindows(p) || proc_family(p) != "intel")

# The products that we will ensure are always built
products = [
    ExecutableProduct("alimask", :alimask),
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

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

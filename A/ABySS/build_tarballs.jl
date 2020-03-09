# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ABySS"
version = v"2.2.4"

# Collection of sources required to build ThinASLBuilder
sources = [
    GitSource("https://github.com/bcgsc/abyss.git",
              "ffd5e372b94b26d1e302271c5fb8f92b85381f0a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/abyss/
./autogen.sh
# configure tries to run the tests `AC_FUNC_MALLOC` `AC_FUNC_REALLOC` which
# automatically fails in cross-compilation environments.  However we have
# verified that for all supported platforms `malloc` and `realloc` are
# well-behaving and return non-null when given 0 as input, so we can cache the
# value of the test.
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-boost=${prefix} \
    --without-sparsehash \
    --disable-werror \
    ac_cv_func_malloc_0_nonnull=yes \
    ac_cv_func_realloc_0_nonnull=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ABYSS", :ABYSS),
    ExecutableProduct("abyss-align", :abyss_align),
    ExecutableProduct("abyss-bloom", :abyss_bloom),
    ExecutableProduct("abyss-bloom-dbg", :abyss_bloom_dbg),
    ExecutableProduct("abyss-bloom-dist.mk", :abyss_bloom_dist_mk),
    ExecutableProduct("abyss-bowtie", :abyss_bowtie),
    ExecutableProduct("abyss-bowtie2", :abyss_bowtie2),
    ExecutableProduct("abyss-bwa", :abyss_bwa),
    ExecutableProduct("abyss-bwamem", :abyss_bwamem),
    ExecutableProduct("abyss-bwasw", :abyss_bwasw),
    ExecutableProduct("abyss-db-txt", :abyss_db_txt),
    ExecutableProduct("abyss-dida", :abyss_dida),
    ExecutableProduct("abyss-fac", :abyss_fac),
    ExecutableProduct("abyss-fatoagp", :abyss_fatoagp),
    ExecutableProduct("abyss-filtergraph", :abyss_filtergraph),
    ExecutableProduct("abyss-fixmate", :abyss_fixmate),
    ExecutableProduct("abyss-fixmate-ssq", :abyss_fixmate_ssq),
    ExecutableProduct("abyss-gapfill", :abyss_gapfill),
    ExecutableProduct("abyss-gc", :abyss_gc),
    ExecutableProduct("abyss-index", :abyss_index),
    ExecutableProduct("abyss-junction", :abyss_junction),
    ExecutableProduct("abyss-kaligner", :abyss_kaligner),
    ExecutableProduct("abyss-layout", :abyss_layout),
    ExecutableProduct("abyss-longseqdist", :abyss_longseqdist),
    ExecutableProduct("abyss-map", :abyss_map),
    ExecutableProduct("abyss-map-ssq", :abyss_map_ssq),
    ExecutableProduct("abyss-mergepairs", :abyss_mergepairs),
    ExecutableProduct("abyss-overlap", :abyss_overlap),
    ExecutableProduct("ABYSS-P", :ABYSS_P),
    ExecutableProduct("abyss-paired-dbg", :abyss_paired_dbg),
    ExecutableProduct("abyss-paired-dbg-mpi", :abyss_paired_dbg_mpi),
    ExecutableProduct("abyss-pe", :abyss_pe),
    ExecutableProduct("abyss-samtoafg", :abyss_samtoafg),
    ExecutableProduct("abyss-scaffold", :abyss_scaffold),
    ExecutableProduct("abyss-sealer", :abyss_sealer),
    ExecutableProduct("abyss-stack-size", :abyss_stack_size),
    ExecutableProduct("abyss-tabtomd", :abyss_tabtomd),
    ExecutableProduct("abyss-todot", :abyss_todot),
    ExecutableProduct("abyss-tofastq", :abyss_tofastq),
    ExecutableProduct("AdjList", :AdjList),
    ExecutableProduct("Consensus", :Consensus),
    ExecutableProduct("DAssembler", :DAssembler),
    ExecutableProduct("DistanceEst", :DistanceEst),
    ExecutableProduct("DistanceEst-ssq", :DistanceEst_ssq),
    ExecutableProduct("KAligner", :KAligner),
    ExecutableProduct("konnector", :konnector),
    ExecutableProduct("logcounter", :logcounter),
    ExecutableProduct("MergeContigs", :MergeContigs),
    ExecutableProduct("MergePaths", :MergePaths),
    ExecutableProduct("Overlap", :Overlap),
    ExecutableProduct("ParseAligns", :ParseAligns),
    ExecutableProduct("PathConsensus", :PathConsensus),
    ExecutableProduct("PathOverlap", :PathOverlap),
    ExecutableProduct("PopBubbles", :PopBubbles),
    ExecutableProduct("SimpleGraph", :SimpleGraph),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("boost_jll"),
    Dependency("OpenMPI_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

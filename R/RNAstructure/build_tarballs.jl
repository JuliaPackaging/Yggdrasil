# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "RNAstructure"
version = v"6.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://rna.urmc.rochester.edu/Releases/$(version.major).$(version.minor)/RNAstructureSource.tgz",
                  "e2a372a739153293185eeffee3d3265f9f50dc6976053a1d013ccf086b06d975"),
]

# TODO
# - Multifind program needs libsvm
# - build binaries with CUDA support

# Notes
# https://rna.urmc.rochester.edu/Overview/Building_Requirements.html
# https://rna.urmc.rochester.edu/Overview/Building.html

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/RNAstructure*/

# `make all` implies `make serial` and `make SMP`
make -j${nproc} CC=${CC} CXX=${CXX} all

# compile shared library
${CXX} -shared -o "libRNAstructure.${dlext}" \
    -std=c++11 -O3 -fPIC -DNDEBUG \
    $(make src+python_interface_sources | grep -E '\.(cpp|cxx)$')

# install executables
for b in exe/*; do
    install -Dvm 755 "$b" "${bindir}/$(basename "${b}")${exeext}"
done

# install shared library
install -Dvm 755 "libRNAstructure.${dlext}" "${libdir}/"

# install data tables
find data_tables/ -type f -exec \
    install -Dvm 644 '{}' "${prefix}/{}" \;

# install CycleFold data files
find CycleFold/datafiles/ -type f -exec \
    install -Dvm 644 '{}' "${prefix}/{}" \;

install_license gpl.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("AccessFold", :AccessFold),
    ExecutableProduct("AllSub", :AllSub),
    ExecutableProduct("bifold", :bifold),
    ExecutableProduct("bifold-smp", :bifold_smp),
    ExecutableProduct("bipartition", :bipartition),
    ExecutableProduct("bipartition-smp", :bipartition_smp),
    ExecutableProduct("CircleCompare", :CircleCompare),
    ExecutableProduct("ct2dot", :ct2dot),
    ExecutableProduct("CycleFold", :CycleFold),
    ExecutableProduct("design", :design),
    ExecutableProduct("design-smp", :design_smp),
    ExecutableProduct("dot2ct", :dot2ct),
    ExecutableProduct("draw", :draw),
    ExecutableProduct("DuplexFold", :DuplexFold),
    ExecutableProduct("DuplexFold-smp", :DuplexFold_smp),
    ExecutableProduct("dynalign", :dynalign),
    ExecutableProduct("DynalignDotPlot", :DynalignDotPlot),
    ExecutableProduct("dynalign_ii", :dynalign_ii),
    ExecutableProduct("dynalign_ii-smp", :dynalign_ii_smp),
    ExecutableProduct("dynalign-smp", :dynalign_smp),
    ExecutableProduct("EDcalculator", :EDcalculator),
    ExecutableProduct("EDcalculator-smp", :EDcalculator_smp),
    ExecutableProduct("efn2", :efn2),
    ExecutableProduct("efn2-smp", :efn2_smp),
    ExecutableProduct("EnergyPlot", :EnergyPlot),
    ExecutableProduct("EnsembleEnergy", :EnsembleEnergy),
    ExecutableProduct("ETEcalculator", :ETEcalculator),
    ExecutableProduct("ETEcalculator-smp", :ETEcalculator_smp),
    ExecutableProduct("Fold", :Fold),
    ExecutableProduct("Fold-smp", :Fold_smp),
    ExecutableProduct("MaxExpect", :MaxExpect),
    ExecutableProduct("MaxExpect-smp", :MaxExpect_smp),
    ExecutableProduct("multilign", :multilign),
    ExecutableProduct("multilign-smp", :multilign_smp),
    ExecutableProduct("NAPSS", :NAPSS),
    ExecutableProduct("oligoscreen", :oligoscreen),
    ExecutableProduct("oligoscreen-smp", :oligoscreen_smp),
    ExecutableProduct("OligoWalk", :OligoWalk),
    ExecutableProduct("orega", :orega),
    ExecutableProduct("orega-smp", :orega_smp),
    ExecutableProduct("partition", :partition),
    ExecutableProduct("partition-smp", :partition_smp),
    ExecutableProduct("PARTS", :PARTS),
    ExecutableProduct("phmm", :phmm),
    ExecutableProduct("ProbabilityPlot", :ProbabilityPlot),
    ExecutableProduct("ProbablePair", :ProbablePair),
    ExecutableProduct("ProbablePair-smp", :ProbablePair_smp),
    ExecutableProduct("ProbKnot", :ProbKnot),
    ExecutableProduct("ProbKnot-smp", :ProbKnot_smp),
    ExecutableProduct("ProbScan", :ProbScan),
    ExecutableProduct("refold", :refold),
    ExecutableProduct("RemovePseudoknots", :RemovePseudoknots),
    ExecutableProduct("RemovePseudoknots-smp", :RemovePseudoknots_smp),
    ExecutableProduct("Rsample", :Rsample),
    ExecutableProduct("Rsample-smp", :Rsample_smp),
    ExecutableProduct("scorer", :scorer),
    ExecutableProduct("ShapeKnots", :ShapeKnots),
    ExecutableProduct("ShapeKnots-smp", :ShapeKnots_smp),
    ExecutableProduct("stochastic", :stochastic),
    ExecutableProduct("stochastic-smp", :stochastic_smp),
    ExecutableProduct("StructureProb", :StructureProb),
    ExecutableProduct("StructureProb-smp", :StructureProb_smp),
    ExecutableProduct("SymmetryTester", :SymmetryTester),
    ExecutableProduct("TurboFold", :TurboFold),
    ExecutableProduct("TurboFold-smp", :TurboFold_smp),
    ExecutableProduct("TurboHomology", :TurboHomology),
    ExecutableProduct("validate", :validate),
    LibraryProduct("libRNAstructure", :libRNAstructure)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

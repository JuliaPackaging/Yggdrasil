# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "cohomolo"
upstream_version = "1.6.12" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all.

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/cohomolo/releases/download/v$(upstream_version)/cohomolo-$(upstream_version).tar.gz",
                  "9f68a987685affd3510a21c4a7d2b1260a6a98f237c5ac76531e4980616532a8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd cohomolo*

# HACK to workaround need to pass --with-gaproot
mkdir -p $prefix/lib/gap/ # HACK
echo "GAParch=dummy" > $prefix/lib/gap/sysinfo.gap # HACK
echo "GAP_CPPFLAGS=dummy" >> $prefix/lib/gap/sysinfo.gap # HACK

./configure ${prefix}/lib/gap
make -j${nproc}

# copy just the executable
mkdir -p ${prefix}/bin/
cp bin/*/* ${prefix}/bin/

install_license LICENSE

rm $prefix/lib/gap/sysinfo.gap
"""

name = gap_pkg_name(name)

platforms = gap_platforms()

dependencies = Dependency[
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("calcpres.gap", :calcpres_gap),
    ExecutableProduct("cohomology.gap", :cohomology_gap),
    ExecutableProduct("conrun", :conrun),
    ExecutableProduct("crrun", :crrun),
    ExecutableProduct("egrun", :egrun),
    ExecutableProduct("execcmd.gap", :execcmd_gap),
    ExecutableProduct("extprun", :extprun),
    ExecutableProduct("gprun", :gprun),
    ExecutableProduct("grrun", :grrun),
    ExecutableProduct("matcalc", :matcalc),
    ExecutableProduct("normrun", :normrun),
    ExecutableProduct("nqmrun", :nqmrun),
    ExecutableProduct("nqrun", :nqrun),
    ExecutableProduct("pcrun", :pcrun),
    ExecutableProduct("readrels", :readrels),
    ExecutableProduct("scrun", :scrun),
    ExecutableProduct("selgen", :selgen),
    ExecutableProduct("sylrun", :sylrun),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1

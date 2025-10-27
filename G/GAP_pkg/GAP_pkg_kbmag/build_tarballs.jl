# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "kbmag"
upstream_version = "1.5.11" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all.

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/kbmag/releases/download/v$(upstream_version)/kbmag-$(upstream_version).tar.gz",
                  "3112924625b3b2b5d0ae1a84fe7babccaaa900b0044dca37fbf33f8b3f455682"),
]

# Bash recipe for building across all platforms
script = raw"""
cd kbmag*

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
    ExecutableProduct("autcos", :autcos),
    ExecutableProduct("autgroup", :autgroup),
    ExecutableProduct("fsaand", :fsaand),
    ExecutableProduct("fsaandnot", :fsaandnot),
    ExecutableProduct("fsabfs", :fsabfs),
    ExecutableProduct("fsaconcat", :fsaconcat),
    ExecutableProduct("fsacount", :fsacount),
    ExecutableProduct("fsaenumerate", :fsaenumerate),
    ExecutableProduct("fsaexists", :fsaexists),
    ExecutableProduct("fsafilter", :fsafilter),
    ExecutableProduct("fsagrowth", :fsagrowth),
    ExecutableProduct("fsalabmin", :fsalabmin),
    ExecutableProduct("fsalequal", :fsalequal),
    ExecutableProduct("fsamin", :fsamin),
    ExecutableProduct("fsanot", :fsanot),
    ExecutableProduct("fsaor", :fsaor),
    ExecutableProduct("fsaprune", :fsaprune),
    ExecutableProduct("fsareverse", :fsareverse),
    ExecutableProduct("fsastar", :fsastar),
    ExecutableProduct("fsaswapcoords", :fsaswapcoords),
    ExecutableProduct("gpaxioms", :gpaxioms),
    ExecutableProduct("gpcheckmult", :gpcheckmult),
    ExecutableProduct("gpchecksubwa", :gpchecksubwa),
    ExecutableProduct("gpcomp", :gpcomp),
    ExecutableProduct("gpdifflabs", :gpdifflabs),
    ExecutableProduct("gpgenmult", :gpgenmult),
    ExecutableProduct("gpgenmult2", :gpgenmult2),
    ExecutableProduct("gpgeowa", :gpgeowa),
    ExecutableProduct("gpmakefsa", :gpmakefsa),
    ExecutableProduct("gpmakesubwa", :gpmakesubwa),
    ExecutableProduct("gpmicomp", :gpmicomp),
    ExecutableProduct("gpmigenmult", :gpmigenmult),
    ExecutableProduct("gpmigenmult2", :gpmigenmult2),
    ExecutableProduct("gpmigmdet", :gpmigmdet),
    ExecutableProduct("gpmimult", :gpmimult),
    ExecutableProduct("gpmimult2", :gpmimult2),
    ExecutableProduct("gpminkb", :gpminkb),
    ExecutableProduct("gpmult", :gpmult),
    ExecutableProduct("gpmult2", :gpmult2),
    ExecutableProduct("gpsubpres", :gpsubpres),
    ExecutableProduct("gpsubwa", :gpsubwa),
    ExecutableProduct("gpwa", :gpwa),
    ExecutableProduct("kbprog", :kbprog),
    ExecutableProduct("kbprogcos", :kbprogcos),
    ExecutableProduct("makecosfile", :makecosfile),
    ExecutableProduct("midfadeterminize", :midfadeterminize),
    ExecutableProduct("nfadeterminize", :nfadeterminize),
    ExecutableProduct("ppgap", :ppgap),
    ExecutableProduct("ppgap4", :ppgap4),
    ExecutableProduct("wordreduce", :wordreduce),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1200.000"
gap_lib_version = v"400.1200.000"
name = "EDIM"
upstream_version = v"1.3.5" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.2" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("http://www.math.rwth-aachen.de/~Frank.Luebeck/$(name)/$(name)-$(upstream_version).tar.bz2",
                  "edf63b708f84fa0b6940014a616cd4734f4474b3493280e65fc9d2f27ae4d322"),
]

# Bash recipe for building across all platforms
script = raw"""
cd EDIM*

# HACK to fool the EDIM build system
touch ${prefix}/lib/gap/GNUmakefile
mkdir -p ${prefix}/lib/gap
cp ${prefix}/bin/gac ${prefix}/lib/gap/gac
chmod a+x ${prefix}/lib/gap/gac

./configure ${prefix}/lib/gap
make -j${nproc}

# revert the HACK
rm -f ${prefix}/lib/gap/GNUmakefile

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license GPL
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/ediv.so", :ediv),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

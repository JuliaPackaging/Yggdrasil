# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1500.0"
name = "EDIM"
upstream_version = "1.3.8" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://www.math.rwth-aachen.de/~Frank.Luebeck/EDIM/EDIM-$(upstream_version).tar.bz2",
                  "b59bb607bc9831b8224410946c33b12b82b252c662803835197821c2fb18f9e2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd EDIM*

# HACK to fool the EDIM build system
mkdir -p ${prefix}/lib/gap
touch ${prefix}/lib/gap/GNUmakefile
cp ${prefix}/bin/gac ${prefix}/lib/gap/gac
chmod a+x ${prefix}/lib/gap/gac

./configure ${prefix}/lib/gap
make -j${nproc}

# revert the HACK
rm ${prefix}/lib/gap/GNUmakefile
rm ${prefix}/lib/gap/gac

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license GPL
"""

name = gap_pkg_name(name)
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/ediv.so", :ediv),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1

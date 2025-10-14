# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "simpcomp"
upstream_version = "2.1.14" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all.

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/simpcomp-team/simpcomp/releases/download/v$(upstream_version)/simpcomp-$(upstream_version).tar.gz",
                  "2a1a33068b038776d6932f13b5eb63d32b0799906a2ec190f585b2931d724dcd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd simpcomp*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}

# copy just the executable
mkdir -p ${prefix}/bin/
cp bin/bistellar ${prefix}/bin/

install_license COPYING
"""

name = gap_pkg_name(name)

platforms = gap_platforms()
platforms = expand_cxxstring_abis(platforms)

dependencies = Dependency[
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("bistellar", :bistellar),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1

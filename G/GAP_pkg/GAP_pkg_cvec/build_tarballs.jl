# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1190.200"
name = "cvec"
upstream_version = v"2.7.4" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/gap-packages/$(name)/releases/download/v$(upstream_version)/$(name)-$(upstream_version).tar.bz2",
                  "9b1188868935e64a8059966af6c33b5e08fb514aa12567362575d3e96cc942eb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd cvec*
./configure ${prefix}/share/gap/
make -j${nproc}

# copy just the loadable module
mkdir -p ${prefix}/lib/gap/
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/cvec.so", :cvec),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")

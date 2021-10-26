# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1190.200"
name = "io"
upstream_version = v"4.7.1" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/gap-packages/$(name)/releases/download/v$(upstream_version)/$(name)-$(upstream_version).tar.bz2",
                  "622de44d4c9d6f6fd9423f73ba44f0d1ce52f8339c3e13b1f216dfe6880660b7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd io*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/share/gap/
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
    FileProduct("lib/gap/io.so", :io),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")

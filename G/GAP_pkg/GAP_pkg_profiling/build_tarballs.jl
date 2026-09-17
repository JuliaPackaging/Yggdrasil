# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1600.100"
name = "profiling"
upstream_version = "2.6.3" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/profiling/releases/download/v$(upstream_version)/profiling-$(upstream_version).tar.gz",
                  "bbc4868237b88d54eedf4419ace6743dbff16ce32bdc0ebb3bf7f8d65beee335"),
]

# Bash recipe for building across all platforms
script = raw"""
cd profiling*
./configure ${prefix}/lib/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license COPYRIGHT
"""

name = gap_pkg_name(name)
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/profiling.so", :profiling),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")


# rebuild trigger: 1

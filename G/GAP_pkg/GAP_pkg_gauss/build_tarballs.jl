# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1400.0"
gap_lib_version = v"400.1400.0"
name = "gauss"
upstream_version = "2024.11-01" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/homalg-project/homalg_project/releases/download/Gauss-$(upstream_version)/Gauss-$(upstream_version).tar.gz",
                  "67b0e5d72395036a79630f959a8ab06cd19ac1c58569fee241d1790be8c0689f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Gauss*
./configure ${prefix}/lib/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/gauss.so", :gauss),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

# rebuild trigger: 1

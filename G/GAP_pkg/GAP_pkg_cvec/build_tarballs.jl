# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1200.200"
gap_lib_version = v"400.1201.200"
name = "cvec"
upstream_version = "2.7.6" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.2" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/cvec/releases/download/v$(upstream_version)/cvec-$(upstream_version).tar.gz",
                  "a06b10295a8a109b27a8f48d86d92ad94e0efcde1f37b6b7d88efbb297b8bd5e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd cvec*
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
    FileProduct("lib/gap/cvec.so", :cvec),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


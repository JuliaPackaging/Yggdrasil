# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1300.0"
gap_lib_version = v"400.1300.0"
name = "json"
upstream_version = "2.2.0" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/json/releases/download/v$(upstream_version)/json-$(upstream_version).tar.gz",
                  "94c9f9fcf0631d053f4d297c9d7cb42f7d704e1897ee5f48bfb183715b6c8a1a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd json*
./configure ${prefix}/lib/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/json.so", :json),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


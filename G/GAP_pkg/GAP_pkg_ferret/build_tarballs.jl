# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1400.0"
gap_lib_version = v"400.1401.0"
name = "ferret"
upstream_version = "1.0.14" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.1" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/ferret/releases/download/v$(upstream_version)/ferret-$(upstream_version).tar.gz",
                  "6e9b7e5aa98dbcafaf5630560b53d42c53dd97d4c7137c2bcf80045c4710d995"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ferret*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/lib/gap
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
    FileProduct("lib/gap/ferret.so", :ferret),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

# rebuild trigger: 1

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1200.200"
gap_lib_version = v"400.1201.200"
name = "NormalizInterface"
upstream_version = "1.3.5" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/NormalizInterface/releases/download/v$(upstream_version)/NormalizInterface-$(upstream_version).tar.gz",
                  "3a5caa2c77f557a8ef5f18be4c0fc2a97487e4f71ae49b58ec76dab7ac55bd8a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd NormalizInterface*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/lib/gap --with-normaliz=${prefix}
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)
platforms = expand_cxxstring_abis(platforms)

push!(dependencies, Dependency("normaliz_jll", compat = "~300.900.300"))

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/NormalizInterface.so", :NormalizInterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


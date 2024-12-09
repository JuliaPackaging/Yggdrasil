# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1400.0"
gap_lib_version = v"400.1400.0"
name = "float"
upstream_version = "1.0.5" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/gap-packages/float/releases/download/v$(upstream_version)/float-$(upstream_version).tar.gz",
                  "d7c07cc3fe892c2fd8a808624ee3e24d5412e44e38325a7e946bab821d3b75a0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd float*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/lib/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license COPYING
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)
platforms = expand_cxxstring_abis(platforms)

append!(dependencies, [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("MPFR_jll", v"4.1.1"),
    Dependency("MPC_jll"),
    Dependency("MPFI_jll"),
])

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/float.so", :float_), # use `float_` to avoid clash with `Base.float`
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


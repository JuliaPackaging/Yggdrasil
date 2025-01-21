# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1400.0"
gap_lib_version = v"400.1401.0"
name = "cddinterface"
upstream_version = "2024.09.02" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.1" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/homalg-project/CddInterface/releases/download/v$(upstream_version)/CddInterface-$(upstream_version).tar.gz",
                  "5a59b6306c2b4e75d499cf1465c0b38a22cc275aa76defcfe62aaa365e1b69d1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd CddInterface*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/lib/gap --with-cddlib=${prefix}
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)

append!(dependencies, [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("cddlib_jll"),
])

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/CddInterface.so", :CddInterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

# rebuild trigger: 1

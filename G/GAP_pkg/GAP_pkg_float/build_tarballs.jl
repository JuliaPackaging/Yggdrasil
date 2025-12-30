# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1500.0"
name = "float"
upstream_version = "1.0.9" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/float/releases/download/v$(upstream_version)/float-$(upstream_version).tar.gz",
                  "cf4e87714ef774d5d760ef252f81bcfe6d0b3bb726ae263c602c68cd5d3a495b"),
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
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()
platforms = expand_cxxstring_abis(platforms)

# TODO: re-enable the below platforms once the deps supports them
filter!(p -> arch(p) != "riscv64", platforms)

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
               julia_compat="1.10", preferred_gcc_version=v"7")


# rebuild trigger: 1

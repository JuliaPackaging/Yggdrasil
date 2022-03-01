# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1192.000"
gap_lib_version = v"400.1192.000"
name = "NormalizInterface"
upstream_version = v"1.3.0" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.1" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/gap-packages/$(name)/releases/download/v$(upstream_version)/$(name)-$(upstream_version).tar.bz2",
                  "5fd7a1e13bbd48cd119456745f00f8208cd09109c0f6614f0165e1965b92afdd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd NormalizInterface*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/NormalizInterface.patch

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/share/gap --with-normaliz=${prefix}
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version; uses_cxx = true)

push!(dependencies, Dependency("normaliz_jll", compat = "~300.900.100")) # version 3.9.1

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/NormalizInterface.so", :NormalizInterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

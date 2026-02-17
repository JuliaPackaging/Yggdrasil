# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1500.0"
name = "cddinterface"
upstream_version = "2025.06.24" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/homalg-project/CddInterface/releases/download/v$(upstream_version)/CddInterface-$(upstream_version).tar.gz",
                  "fc3f4ae2b4cb27152bf82d3a64a3aec63be283c83090e586204540a12b0d4883"),
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
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()

append!(dependencies, [
    Dependency("GMP_jll", v"6.2.1"),
    Dependency("cddlib_jll", v"0.94.15"),
])

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/CddInterface.so", :CddInterface),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1

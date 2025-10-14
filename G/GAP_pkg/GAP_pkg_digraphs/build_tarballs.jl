# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1500.0"
name = "digraphs"
upstream_version = "1.13.1" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/digraphs/Digraphs/releases/download/v$(upstream_version)/digraphs-$(upstream_version).tar.gz",
                  "b965094b187b448c36edac9eb8400809adcd3045df7067aea47ba3dd5fec7396"),
]

# Bash recipe for building across all platforms
script = raw"""
cd digraphs*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/lib/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap/
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/digraphs.so", :digraphs),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1

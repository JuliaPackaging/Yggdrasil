# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1192.000"
gap_lib_version = v"400.1192.000"
name = "ferret"
upstream_version = v"1.0.5" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.2" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/gap-packages/$(name)/releases/download/v$(upstream_version)/$(name)-$(upstream_version).tar.gz",
                  "08ae9cd65c5e086962ca9025d5d51e03b1cc1ccaa39f52aeeff47bf79c6c17e8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ferret*

for f in ${WORKSPACE}/srcdir/patches/ferret*.patch; do
    atomic_patch -p1 ${f}
done

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gaproot=${prefix}/share/gap
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version; uses_cxx = true)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/ferret.so", :ferret),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

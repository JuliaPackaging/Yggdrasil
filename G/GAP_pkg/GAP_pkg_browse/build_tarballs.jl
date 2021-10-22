# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1191.001"
gap_lib_version = v"400.1191.000"
name = "Browse"
upstream_version = v"1.8.12" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://www.math.rwth-aachen.de/~Browse/$(name)-$(upstream_version).tar.bz2",
                  "6ee674b3f1877e550bacb302335fca7c707f4eb742428d8be7781f8aa77c8b9b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Browse*

# HACK to fool the Browse build system
ln -s sysinfo.gap ${prefix}/share/gap/sysinfo.gap-default64

./configure ${prefix}/share/gap
make -j${nproc} CFLAGS="-I$prefix/include/ncurses"

# revert the HACK
rm -f ${prefix}/share/gap/sysinfo.gap-default64

# copy the loadable module
mkdir -p ${prefix}/lib/gap/
cp bin/*/*.so ${prefix}/lib/gap/

install_license /usr/share/licenses/GPL3
"""

name = gap_pkg_name(name)
platforms, dependencies = setup_gap_package(gap_version, gap_lib_version)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/ncurses.so", :ncurses),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1200.000"
gap_lib_version = v"400.1200.000"
name = "Browse"
upstream_version = v"1.8.14" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://www.math.rwth-aachen.de/~Browse/$(name)-$(upstream_version).tar.bz2",
                  "f600ca9286170f8fbc2f4c08694ec1067be3a1b2c3ce0f67a36e3a88b0cf6d5d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Browse*

# HACK to fool the Browse build system
mkdir -p ${prefix}/lib/gap
cp ${prefix}/bin/gac ${prefix}/lib/gap/gac
chmod a+x ${prefix}/lib/gap/gac

./configure ${prefix}/lib/gap
make -j${nproc} CFLAGS="-I$includedir -I$includedir/ncurses"

# revert the HACK
rm ${prefix}/lib/gap/gac

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license /usr/share/licenses/GPL-3.0+
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


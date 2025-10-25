# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "ace"
upstream_version = "5.7.0" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all.

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/ace/releases/download/v$(upstream_version)/ace-$(upstream_version).tar.gz",
                  "7123e4100f1340a791d20bca1a8d9e6d9f09fe74a1c5fb15f1723899a1bb4553"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ace*

# HACK to workaround need to pass --with-gaproot
mkdir -p $prefix/lib/gap/ # HACK
echo "GAParch=dummy" > $prefix/lib/gap/sysinfo.gap # HACK
echo "GAP_CPPFLAGS=dummy" >> $prefix/lib/gap/sysinfo.gap # HACK

./configure ${prefix}/lib/gap
make -j${nproc}

# copy just the executable
mkdir -p ${prefix}/bin/
cp bin/*/* ${prefix}/bin/

install_license LICENSE

rm $prefix/lib/gap/sysinfo.gap
"""

name = gap_pkg_name(name)

platforms = gap_platforms()

dependencies = Dependency[
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("ace", :ace),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")


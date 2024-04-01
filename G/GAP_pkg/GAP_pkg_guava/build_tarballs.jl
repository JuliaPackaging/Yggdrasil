# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "guava"
upstream_version = "3.18" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all,
# hence we don't include common.jl

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/guava/releases/download/v$(upstream_version)/guava-$(upstream_version).tar.gz",
                  "d2ec6474d5e85c0b997970cf4f4576970d8cc18fbcf8310ea28e7ba300c9ba5d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd guava*

# HACK to workaround need to pass --with-gaproot
mkdir -p $prefix/lib/gap/ # HACK
echo "GAParch=dummy" > $prefix/lib/gap/sysinfo.gap # HACK
echo "GAP_CPPFLAGS=dummy" >> $prefix/lib/gap/sysinfo.gap # HACK

# HACK to get the 'inner' configure to see the host config
sed -i -e "s|./configure;|./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target};|" Makefile.in

./configure ${prefix}/lib/gap
make -j${nproc}

# copy just the executable
mkdir -p ${prefix}/bin/
cp bin/*/* ${prefix}/bin/

install_license COPYING

rm $prefix/lib/gap/sysinfo.gap
"""

name = gap_pkg_name(name)

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
filter!(!Sys.iswindows, platforms)      # Windows is not supported

dependencies = Dependency[
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("desauto", :desauto),
    ExecutableProduct("leonconv", :leonconv),
    ExecutableProduct("minimum-weight", :minimum_weight),
    ExecutableProduct("wtdist", :wtdist),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "anupq"
upstream_version = "3.3.1" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all,
# hence we don't include common.jl

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/anupq/releases/download/v$(upstream_version)/anupq-$(upstream_version).tar.gz",
                  "fba1526f9e904e13ee7a9b980c795fbf27a8276c6734d684c1f91ebb3a1926b6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd anupq*

# HACK to workaround need to pass --with-gaproot
mkdir -p $prefix/lib/gap/ # HACK
echo "GAParch=dummy" > $prefix/lib/gap/sysinfo.gap # HACK
echo "GAP_CPPFLAGS=dummy" >> $prefix/lib/gap/sysinfo.gap # HACK

# HACK: avoid "undefined reference 'rpl_malloc'" errors; this is fixed in version 3.3.0
sed -i -e '/ALLOC/d' configure.ac
./autogen.sh

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix} --with-gaproot=${prefix}/lib/gap
make -j${nproc}

# copy just the executable
mkdir -p ${prefix}/bin/
cp bin/*/pq ${prefix}/bin/

install_license LICENSE

rm $prefix/lib/gap/sysinfo.gap
"""

name = gap_pkg_name(name)

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
filter!(!Sys.iswindows, platforms)      # Windows is not supported

dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pq", :pq),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


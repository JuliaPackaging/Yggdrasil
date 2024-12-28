# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "fplsa"
upstream_version = "1.2.6" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version
version = offset_version(upstream_version, offset)

# This package only produces an executable and does not need GAP for this at all,
# hence we don't include common.jl

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/gap-packages/FPLSA/releases/download/v$(upstream_version)/FPLSA-$(upstream_version).tar.gz",
                  "cd9fb93eb4198955070d836575e15f6e156c7fee417fef9c42c8fc3502ba422f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd FPLSA*

# HACK to workaround need to pass --with-gaproot
mkdir -p $prefix/lib/gap/ # HACK
echo "GAParch=dummy" > $prefix/lib/gap/sysinfo.gap # HACK
echo "GAP_CPPFLAGS=dummy" >> $prefix/lib/gap/sysinfo.gap # HACK

./configure ${prefix}/lib/gap
make -j${nproc}

# copy just the executable
mkdir -p ${prefix}/bin/
cp bin/*/fplsa4 ${prefix}/bin/

install_license LICENSE

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
    ExecutableProduct("fplsa4", :fplsa4),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")


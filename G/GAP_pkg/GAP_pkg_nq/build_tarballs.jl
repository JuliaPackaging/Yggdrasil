# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

name = "nq"
upstream_version = v"2.5.5" # when you increment this, reset offset to v"0.0.0"
offset = v"0.0.0" # increment this when rebuilding with unchanged upstream_version
version = offset_version(upstream_version, offset)

# nq just produces a binary and does not need GAP for this at all.
# So let's *not* use common.jl

# Collection of sources required to build libsingular-julia
sources = [
    ArchiveSource("https://github.com/gap-packages/$(name)/releases/download/v$(upstream_version)/$(name)-$(upstream_version).tar.bz2",
                  "b7a8fa12c02db78dc05ce047b451e7855345608bbfb0d11eb105056527694e42"),
    DirectorySource("../bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd nq*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/nq.patch
autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix}
make -j${nproc}

# copy just the nq executable
mkdir -p ${prefix}/bin/
cp bin/nq ${prefix}/bin/

install_license LICENSE
"""

name = gap_pkg_name(name)

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
filter!(!Sys.iswindows, platforms)      # Windows is not supported

dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("nq", :nq),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")

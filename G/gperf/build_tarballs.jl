# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gperf"
version = v"3.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz", "588546b945bba4b70b6a3a616e80b4ab466e3f33024a352fc2198112cdbb3ae2")
]

# Bash recipe for building across all platforms
script = raw"""
cd gperf-*
install_license COPYING

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gperf", :gperf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

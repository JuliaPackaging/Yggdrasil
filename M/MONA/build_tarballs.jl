# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MONA"
version = v"1.4.18"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.brics.dk/mona/download/mona-1.4-18.tar.gz",
                  "ece10e1e257dcae48dd898ed3da48f550c6b590f8e5c5a6447d0f384ac040e4c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mona*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
extra=""
if [[ "${target}" == *-apple-* ]]; then
  extra="LDFLAGS=-shared -undefined dynamic_lookup -Wl"
fi
make -j${nproc} ${extra}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mona", :mona)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)

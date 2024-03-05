# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Btop"
version = v"1.3.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/aristocratos/btop.git",
              "fd2a2acdad6fbaad76846cb5e802cf2ae022d670"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/btop*/
if [[ "${target}" == *-freebsd* ]]; then
    # Don't do lto, doesn't seem to work on FreeBSD
    OPTFLAGS="-O3 -ftree-vectorize"
else
    OPTFLAGS="-O3 -ftree-vectorize -flto=${nprocs}"
fi
if [[ "${target}" == x86_64-linux-gnu ]] || [[ "${target}" == aarch64-linux-gnu ]]; then
    # Enable GPU also on aarch64
    GPU_SUPPORT=true
    # But this needs to explicitly link to libdl for `dlerror` symbol
    ADDFLAGS="-ldl"
else
    GPU_SUPPORT=false
    ADDFLAGS=""
fi

make -j${nproc} OPTFLAGS="${OPTFLAGS}" ADDFLAGS="${ADDFLAGS}" GPU_SUPPORT="${GPU_SUPPORT}"
make install PREFIX=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows); skip=Returns(false))

# The products that we will ensure are always built
products = [
    ExecutableProduct("btop", :btop)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # Contrary to documentation (<https://github.com/aristocratos/btop/blob/c767099d765b0094c50b8c66030aeacff26f56ef/README.md#compilation-linux>),
               # this requires GCC 11
               julia_compat = "1.6", preferred_gcc_version=v"11")
